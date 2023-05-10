# Vaultwarden native deb builder

## About

This builder I wrote for my own purposes but you can use it for yourself too.
You have to install:

- Rust
- Rust toolchain for your platform (see `rustc --print target-list`)
- Cargo cross to build vaultwarden in Docker. You can also change compiler to cargo and build vaultwarden on your host machine.
- Node with NPM to build web-vault
- FPM to package all of this in deb or any supported package (see [GitHub repo](https://github.com/jordansissel/fpm))

## License
All credits are going to [dani-garcia](https://github.com/dani-garcia).
