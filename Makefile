.RECIPEPREFIX = >
MODULE_ID := lmkd_tune
ZIP       := module.zip
FILES     := module.prop system.prop service.sh

all: $(ZIP)

$(ZIP): $(FILES)
> rm -f $(ZIP)
> zip -r -y $(ZIP) $(FILES)

install: $(ZIP)
> cp $(ZIP) /sdcard/Download/$(MODULE_ID).zip
> @echo "-> /sdcard/Download/$(MODULE_ID).zip"

clean:
> rm -f $(ZIP)

.PHONY: all install clean
