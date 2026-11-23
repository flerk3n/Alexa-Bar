# Third-party software

Release builds of Alexa Bar bundle the software below inside
`Alexa Bar.app/Contents/Resources/helper/`. Each component keeps its own
license. Full license texts ship in the app: CPython's in
`python/lib/python3.12/LICENSE.txt`, and each Python package's in its
`site-packages/<package>.dist-info/` folder.

| Component | Version | License |
| --- | --- | --- |
| [CPython](https://www.python.org) via [python-build-standalone](https://github.com/astral-sh/python-build-standalone) | 3.12.16 | PSF-2.0 (plus licenses of bundled libraries such as OpenSSL, listed in CPython's LICENSE.txt) |
| [AlexaPy](https://gitlab.com/keatontaylor/alexapy) | 1.36.0 | Apache-2.0 |
| [authcaptureproxy](https://github.com/alandtse/auth_capture_proxy) | 1.3.9 | Apache-2.0 |
| [aiohttp](https://github.com/aio-libs/aiohttp) | 3.14.5 | Apache-2.0 AND MIT |
| aiofiles | 25.1.0 | Apache-2.0 |
| aiohappyeyeballs | 2.7.1 | PSF-2.0 |
| aiosignal | 1.4.0 | Apache-2.0 |
| annotated-doc | 0.0.7 | MIT |
| annotated-types | 0.8.0 | MIT |
| anyio | 4.16.0 | MIT |
| attrs | 26.1.0 | MIT |
| backoff | 2.2.1 | MIT |
| beautifulsoup4 | 4.15.0 | MIT |
| certifi | 2026.11.20 | MPL-2.0 |
| cffi | 2.1.1 | MIT-0 |
| charset-normalizer | 3.5.3 | MIT |
| cryptography | 50.0.2 | Apache-2.0 OR BSD-3-Clause |
| frozenlist | 1.8.0 | Apache-2.0 |
| h11 | 0.16.0 | MIT |
| h2 | 4.4.1 | MIT |
| hpack | 4.2.0 | MIT |
| httpcore | 1.0.9 | BSD-3-Clause |
| httpx | 0.28.1 | BSD-3-Clause |
| hyperframe | 6.1.0 | MIT |
| idna | 3.20 | BSD-3-Clause |
| multidict | 6.9.1 | Apache-2.0 |
| propcache | 0.5.4 | Apache-2.0 |
| pycparser | 3.12 | BSD-3-Clause |
| pydantic | 2.14.4 | MIT |
| pydantic-core | 2.50.5 | MIT |
| PyOTP | 2.12.1 | MIT |
| requests | 2.34.2 | Apache-2.0 |
| simplejson | 4.3.0 | MIT OR AFL-2.1 |
| soupsieve | 4.1.3 | MIT |
| typing-extensions | 4.16.0 | PSF-2.0 |
| typing-inspection | 0.4.5 | MIT |
| urllib3 | 2.8.0 | MIT |
| yarl | 1.25.1 | Apache-2.0 |

Alexa, Echo and all related logos are trademarks of Amazon.com, Inc. or its
affiliates. Alexa Bar is an independent project and is not affiliated with,
endorsed by, or sponsored by Amazon. The app's ring icon is original artwork.
