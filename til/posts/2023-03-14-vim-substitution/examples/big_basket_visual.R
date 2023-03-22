# Replace each instance of carrot with kale using visual modes
# Move cursor to line where you want to start
# Start visual mode 'v'
# Highlight selection
# :'<,'>s/carrot/kale
library(tribble)

basket <- tribble(
   ~fruit,       ~veggie,
   "apple",      "carrot",
   "apple",      "pepper",
   "banana",     "carrot",
   "pears",      "carrot",
   "strawberry", "asparagus"
)
