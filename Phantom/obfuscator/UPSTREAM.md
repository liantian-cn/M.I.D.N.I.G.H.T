# Vendored LuaObfuscator Runtime

The runtime files in `lua_obfuscator/` come from
[`jkusner/LuaObfuscator`](https://github.com/jkusner/LuaObfuscator) at commit
`3d168a6a40d9eb644ff5855bfaa7a78b70480f20`. Each source URL is pinned to that
commit. Only the seven files needed by level 2 were downloaded; upstream's CLI
and the other decrypt templates were not vendored.

## Downloaded files

| File | Pinned source | Upstream SHA-256 | Local SHA-256 |
| --- | --- | --- | --- |
| `obfuscator.py` | [source](https://raw.githubusercontent.com/jkusner/LuaObfuscator/3d168a6a40d9eb644ff5855bfaa7a78b70480f20/obfuscator.py) | `bd75831283ac023df83a19b7a3807ce4884d91433aa82069476cb66e85773d8f` | `26c08eee68c325ed838a41a0c65f286c33ae2f58c31fd2aafef19cf9b433b0c3` |
| `finalize.py` | [source](https://raw.githubusercontent.com/jkusner/LuaObfuscator/3d168a6a40d9eb644ff5855bfaa7a78b70480f20/finalize.py) | `86c39809d763929eb1c0bfcedab59b5a7d50797a1d1aa19fdffa3790b48e7bdf` | `f6a962af9f50155319c6ef3c49d541ff1a26edb6861dab3499407489b5d1d6e4` |
| `stringencoder.py` | [source](https://raw.githubusercontent.com/jkusner/LuaObfuscator/3d168a6a40d9eb644ff5855bfaa7a78b70480f20/stringencoder.py) | `9a1f8ee810e1077b5f55b8e83076a2540e7559f14d5d1e4bd1d5b54b1f32ad8f` | `61bae76331a5ebf057fd7c1f2aab4917adba1278e360bde6ab0af7a115f1827b` |
| `stringstripper.py` | [source](https://raw.githubusercontent.com/jkusner/LuaObfuscator/3d168a6a40d9eb644ff5855bfaa7a78b70480f20/stringstripper.py) | `cb96b4b5b6a30fde6bd40f2eb7d1ed197444bd7679e2596c50aaa1a1819301bf` | `cb96b4b5b6a30fde6bd40f2eb7d1ed197444bd7679e2596c50aaa1a1819301bf` |
| `tokenizer.py` | [source](https://raw.githubusercontent.com/jkusner/LuaObfuscator/3d168a6a40d9eb644ff5855bfaa7a78b70480f20/tokenizer.py) | `d279486bb2e2ce6ce92b611f984912aacce8ab54b5a381161c80291a30db36c3` | `d279486bb2e2ce6ce92b611f984912aacce8ab54b5a381161c80291a30db36c3` |
| `globals.json` | [source](https://raw.githubusercontent.com/jkusner/LuaObfuscator/3d168a6a40d9eb644ff5855bfaa7a78b70480f20/globals.json) | `c165f0c631a40e021fa7aa095c3f4746a1621c1193186728596a1fa74a2c7faa` | `c165f0c631a40e021fa7aa095c3f4746a1621c1193186728596a1fa74a2c7faa` |
| `__decrypt_2.lua` | [source](https://raw.githubusercontent.com/jkusner/LuaObfuscator/3d168a6a40d9eb644ff5855bfaa7a78b70480f20/__decrypt_2.lua) | `9e32e7bd17da621ad422566d895e87fc678ea0e82cb4048d5fc00979a45154ce` | `9e32e7bd17da621ad422566d895e87fc678ea0e82cb4048d5fc00979a45154ce` |

Hashes in the upstream column were calculated immediately after download.
Local hashes were calculated after the adaptations below. Unchanged rows remain
byte-for-byte identical to upstream.

## Local adaptations

- `obfuscator.py` imports `finalize`, `stringstripper`, and `tokenizer` through
  relative package imports.
- `finalize.py` imports `tokenizer` through a relative package import.
- `stringencoder.py` imports `obfuscator` through a relative package import and
  resolves `__decrypt_<level>.lua` beside the module instead of against the
  process working directory.
- `__init__.py` is local package scaffolding and has no upstream counterpart.
- State reset, globals reloading, UTF-8 file handling, error translation,
  logging, discovery, and transactional output handling live in `../main.py`;
  they do not alter the upstream algorithm.

## License and compatibility notice

No license file or license declaration was detected in the pinned upstream
tree. Local inclusion does not grant redistribution rights. Any publication or
redistribution requires a separate authorization and licensing review.

This is an unmaintained 2016 heuristic transformer. Known risk areas include
method calls, varargs, nested indexing, Unicode identifiers and strings, and
large files. Level 2 is reversible obfuscation, not encryption. Output is
randomized and is not byte-for-byte reproducible. Vendoring and offline tests
do not establish semantic equivalence, WoW Lua parser compatibility, or WoW
12.1 runtime compatibility.
