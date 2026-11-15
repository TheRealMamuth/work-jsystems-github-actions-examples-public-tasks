# Jest to plik gdzie mozemy dokonfigurowac dodatkowe argumenty do naszych providerow, tutaj tez mozemy dokonfigurowac nasze rozne regiony czy tez inne parametry.

provider "digitalocean" {
  token = var.do_token
}