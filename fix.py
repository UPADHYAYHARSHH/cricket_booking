lines = open('lib/user_booking/presentation/widgets/slot_selection_widgets.dart', 'r', encoding='utf-8').readlines()

# delete 2276 to 2440 (0-indexed)
del lines[2276:2441]

# delete 501 to 622 (0-indexed)
del lines[501:623]

# delete 213 to 317 (0-indexed)
del lines[213:318]

open('lib/user_booking/presentation/widgets/slot_selection_widgets.dart', 'w', encoding='utf-8').writelines(lines)
print('Fixed lines')
