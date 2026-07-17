# 编译阶段
FROM golang:alpine AS build_base
# 替换国内源，避免构建时apk网络报错
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apk/repositories
RUN apk add --no-cache git gcc ca-certificates libc-dev
WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download
COPY . .
# 编译剥离符号、缩小二进制
RUN CGO_ENABLED=1 go build -ldflags "-w -s" -trimpath -o speedtest main.go

# 运行阶段（升级alpine 3.20，替换国内源）
FROM alpine:3.20
# 替换清华源
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apk/repositories
WORKDIR /app
# 直接拷贝编译阶段的证书，不再apk add ca-certificates（根除arm64 apk报错）
COPY --from=build_base /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=build_base /src/speedtest .
COPY --from=build_base /src/web/assets ./assets
COPY --from=build_base /src/settings.toml .

# 优化权限，取消777
RUN mkdir ./config \
    && cp ./settings.toml ./config/settings.toml \
    && chmod 644 ./config/settings.toml \
    && chmod 755 ./config

EXPOSE 8989
VOLUME ["/app/config"]
CMD ["./speedtest"]