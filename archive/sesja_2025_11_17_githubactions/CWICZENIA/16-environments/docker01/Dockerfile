FROM alpine:3.20

ARG APP_ENV=dev

RUN echo "Hello from environment: ${APP_ENV}" > /message.txt

CMD ["cat", "/message.txt"]
