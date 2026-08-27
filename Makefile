.RECIPEPREFIX = >
MODULE_ID := lmkd_tune
ZIP       := module.zip
FILES     := module.prop system.prop post-fs-data.sh service.sh

all: $(ZIP)

$(ZIP): $(FILES)
> chmod 755 post-fs-data.sh service.sh
> rm -f $(ZIP)
> zip -r -y $(ZIP) $(FILES)

install: $(ZIP)
> cp $(ZIP) /sdcard/Download/$(MODULE_ID).zip
> @echo "-> /sdcard/Download/$(MODULE_ID).zip"

clean:
> rm -f $(ZIP)

.PHONY: all install clean
