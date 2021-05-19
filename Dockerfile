ARG GIT_COMMIT
ARG VERSION
ARG IMG_REG
ARG ENVIRONMENT
ARG SERVICE_NAME

# Build Stage
FROM $IMG_REG/golang:1.13.7 AS builder

ARG GIT_COMMIT
ARG VERSION
ARG IMG_REG
ARG ENVIRONMENT
ARG SERVICE_NAME

ADD . /code/mw-wms

WORKDIR /code/mw-wms

#RUN make build
#RUN make ENV=$ENVIRONMENT SVC=$SERVICE_NAME build

##saya pindah di makefile > make build
RUN go mod download
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -a -ldflags '-extldflags "-static"' -o bin/${SERVICE_NAME}/app cmd/$SERVICE_NAME/main.go

# Final Stage
FROM $IMG_REG/zackijack/debian-base-image:buster

ARG GIT_COMMIT
ARG VERSION
ARG IMG_REG
ARG ENVIRONMENT
ARG SERVICE_NAME

#RUN apk add --no-cache ca-certificates
#RUN apk add --no-cache tzdata
ENV TZ=Asia/Jakarta
ENV PATH=$PATH:/opt/isirumahid/bin
RUN apt update
RUN apt install -y --fix-missing curl
RUN apt install -y --fix-missing nano

WORKDIR /root/

RUN mkdir logs
RUN chmod 777 logs

WORKDIR /opt/isirumahid/bin

COPY --from=builder /code/isirumahid/bin/$SERVICE_NAME/app /opt/isirumahid/bin
COPY --from=builder /code/isirumahid/config/$SERVICE_NAME/config$ENVIRONMENT.json /opt/isirumahid/bin/config/$SERVICE_NAME/config.json

RUN chmod +x /opt/isirumahid/bin/app

ENV COMRUN = /opt/isirumahid/bin/app
# Create appuser
RUN adduser --disabled-password --gecos '' mw-wms
USER mw-wms

ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD ["/opt/isirumahid/bin/app"]
EXPOSE 9090
