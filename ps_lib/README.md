Informações:
ps_lib é usado nas releases da Platinum Scripts. ps_lib é um fork do ox_lib feito pela Overextended. Este repositório permanecerá público em conformidade com a licença original.

---

<div align='center'><h1><a href='https://overextended.github.io/docs/'>Documentação</a></h3></div>
<br>

## Biblioteca Lua para FiveM

O FXServer fornece seu próprio sistema para inclusão de arquivos, que usamos para carregar este recurso no fxmanifest por meio de

```lua
shared_script '@ps_lib/init.lua'
```

### server.cfg

```
add_ace resource.ps_lib command.add_ace allow
add_ace resource.ps_lib command.remove_ace allow
add_ace resource.ps_lib command.add_principal allow
add_ace resource.ps_lib command.remove_principal allow
```

## Licença

<a href='https://www.gnu.org/licenses/lgpl-3.0.en.html'>LGPL-3.0-or-later</a>
