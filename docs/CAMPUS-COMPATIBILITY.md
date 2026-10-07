# Campus compatibility

NOC uses standards-first Linux backends so a laptop can move between home,
university labs, libraries, offices and docks without a permanent vendor helper
for every device.

The **Settings → Campus & devices** page is zero-idle: printer and scanner
discovery runs only after pressing **Discover devices**. Names are displayed in
memory and are not written to NOC logs or continuity data.

## Printing

The supported order is:

1. **IPP Everywhere / AirPrint** network printer;
2. **IPP-over-USB** multifunction device through `ipp-usb`;
3. the university's official PaperCut/Mobility Print or web-print package;
4. an administrator-provided CUPS queue or PPD only when the first three are not
   available.

CUPS is the queue backend and Avahi supplies local discovery. Modern driverless
IPP printers do not need a model-specific driver. The CUPS web console remains
available as a fallback, while NOC Settings provides the quick readiness and
discovery surface.

Useful diagnostics:

```bash
lpstat -r
lpstat -e
lpstat -v
```

Never install a random printer script from an unofficial page with root access.
For a managed campus queue, use the package or URI supplied by university IT.

## Scanning

NOC installs SANE plus `sane-airscan` for eSCL/AirScan and WSD devices, and
keeps ordinary USB SANE support. Skanpage is the preferred Qt interface;
Document Scanner (`simple-scan`) remains a broadly compatible fallback.

```bash
scanimage -L
```

Discovery is intentionally bounded because a broken network scanner must not
hang Settings.

## University Wi-Fi and VPN

NetworkManager handles WPA-Enterprise/802.1X and VPN profiles. For eduroam,
download the institution-specific installer/profile from university IT or
[geteduroam](https://www.geteduroam.app/). NOC never asks for, stores, exports,
or syncs campus credentials and never disables server-certificate validation.

Captive portals and browser-based enrollment remain institution workflows.
Smart-card and FIDO2 readiness are displayed when their standard tools are
installed, but private keys stay with the system token stack.

## Service repair

**Repair services** opens a visible terminal and requires typing `REPAIR`. It
enables CUPS socket activation and Avahi discovery; it does not add a queue,
install a proprietary driver, or modify credentials.

## Upstream basis

- [OpenPrinting CUPS](https://openprinting.github.io/cups/)
- [CUPS driverless printing](https://openprinting.github.io/cups/drivers.html)
- [OpenPrinting ipp-usb](https://openprinting.github.io/projects/03-ipp-usb)
- [SANE eSCL backend](https://www.sane-project.org/man/sane-escl.5.html)

