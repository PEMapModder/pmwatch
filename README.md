pmwatch
===
Backend source code for http://pmt.mcpe.me/pmb

## How to use
### Run the auto updater
1. Make sure that you have `php` installed. I used PHP 7, but PHP 5 should be OK too.
1. Create a file `/GITHUB_TOKEN` that contains a GitHub OAuth2 access token of anyone. No scopes required; just need a token (to overcome the rate-limit). Root access required.
1. `git clone` this repo to a directory that your web server has read access to.
1. Create a new screen, `cd` to the directory of the clone and run `./run.sh`.
1. Detach from the screen. Done! New builds

### Create a phar from source
If you just want to create a phar from source:
1. Before everything, the very first thing is to run `./start.sh` in your server directory to make sure that it works!
1. Run `php compile.php --out $OUT`, where `$OUT` is the exact filename to create the phar at. File will be overwritten if exists.

> Note: Only the `src` folder will be included.
