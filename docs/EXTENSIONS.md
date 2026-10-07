# Nocturne declarative extensions

NOC extension contract v1 is deliberately constrained. An extension may expose
an existing native surface, a credential-free HTTPS page, or an installed
desktop entry. It cannot evaluate shell text, Python, QML or native code.

```json
{
  "format": "nocturne-extension-v1",
  "id": "org.example.status",
  "name": "Example status",
  "version": "1.0.0",
  "description": "Open an external status page.",
  "author": "Example",
  "entry": {"type": "url", "target": "https://status.example.org"},
  "permissions": ["network"]
}
```

Install a reviewed local manifest with `nocturne-extensions install FILE`.
Settings shows requested permissions before launch. Disabled extensions consume
no resources; enabled extensions also have zero resident cost because entries
are resolved only when opened.

This narrow contract is the stable foundation. A future executable extension
API requires process isolation, lifecycle supervision, an accessibility
contract and enforceable resource budgets before it can be considered safe.
