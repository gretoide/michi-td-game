class_name LocaleSelector
extends OptionButton

func setup() -> void:
    add_item("EN"); add_item("ES")
    selected = 1 if LocalizationService.locale == "es" else 0
    item_selected.connect(func(index: int): LocalizationService.set_locale("es" if index == 1 else "en"))
    LocalizationService.locale_changed.connect(func(value: String): selected = 1 if value == "es" else 0)
    tooltip_text = LocalizationService.tr_key("locale.label")
