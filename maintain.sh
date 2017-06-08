#!/usr/bin/env bash

rvm get stable --auto-dotfiles

brew doctor
brew prune
brew update

cabal update
