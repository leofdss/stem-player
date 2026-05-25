# stem-player

## Distrobox

[distrobox.ini](./distrobox.ini)

### Starship - Opcional

Dentro do container

```bash
sudo pacman -S starship
```

```bash
echo 'eval "$(starship init bash)"' >> ~/.bashrc
```

### Vscode - Opcional

Dentro do container

```bash
sudo pacman -S code
```

```bash
distrobox-export --app code
```

```bash
code --install-extension rust-lang.rust-analyzer --install-extension vadimcn.vscode-lldb
```
