#!/usr/bin/env sh

echo 'eval "$(starship init bash)"' >> ~/.bashrc

code --install-extension rust-lang.rust-analyzer --install-extension vadimcn.vscode-lldb

npm install -g @fission-ai/openspec@latest
npm install -g @anthropic-ai/claude-code
