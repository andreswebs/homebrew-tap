# andreswebs/tap

## How do I install these formulae and casks?

Install by fully qualified name. This trusts only the item being installed:

```sh
brew install andreswebs/tap/<formula>
brew install --cask andreswebs/tap/<cask>
```

To install by short name, tap the repository and trust the item first.
Homebrew requires explicit trust for non-official taps:

```sh
brew tap andreswebs/tap
brew trust --formula andreswebs/tap/<formula>
brew install <formula>
```

Use `brew trust --cask andreswebs/tap/<cask>` for a cask, or
`brew trust andreswebs/tap` to trust everything in this tap.

In a `brew bundle` `Brewfile`:

```ruby
tap "andreswebs/tap"
brew "andreswebs/tap/<formula>", trusted: true
cask "andreswebs/tap/<cask>", trusted: true
```

## Documentation

`brew help`, `man brew` or check [Homebrew's documentation](https://docs.brew.sh).
See [Tap Trust](https://docs.brew.sh/Tap-Trust) for how trust works.

## Acknowledgements

- Dotnet casks adapted from: <https://github.com/junian/homebrew-dotnet>

## Authors

**Andre Silva** - [@andreswebs](https://github.com/andreswebs)

## License

This project is licensed under the [Unlicense](UNLICENSE).
