# vim-pass
Vim password-store API (currently get only)

see [Pass: The Standard Unix Password Manager](https://www.passwordstore.org/)

## installation
```vim
dein#add('tsuyoshicho/vim-pass')
```

## limitation
- support only get(default password/entry select)
- use under local vim(gvim/cui vim); because need gpg-agent/pinentry
- entry select require exact match
