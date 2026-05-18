FROM golang:alpine AS build_base
#ENV GOARCH arm64
#ENV GOARCH amd64
RUN apk add --no-cache git gcc ca-certificates libc-dev
WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN go build -ldflags "-w -s" -trimpath -o speedtest main.go

FROM alpine:3.15
WORKDIR /app
COPY --from=build_base /src/speedtest .
COPY --from=build_base /src/web/assets ./assets
COPY --from=build_base /src/settings.toml .
RUN apk add ca-certificates \
&& mkdir ./config \
&& cp ./settings.toml ./config/settings.toml \
&& chmod 777 -R ./config

EXPOSE 8989

VOLUME ["/app/config"]

CMD ["./speedtest"]
