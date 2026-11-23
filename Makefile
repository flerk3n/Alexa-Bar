.PHONY: app dmg install clean

# Self-contained Alexa Bar.app in build/
app:
	scripts/build_app.sh

# Drag-to-install disk image in build/
dmg: app
	scripts/make_dmg.sh

# Build and copy to /Applications (or ~/Applications), then open
install: app
	scripts/install.sh

clean:
	rm -rf .build build/"Alexa Bar.app" build/*.dmg
