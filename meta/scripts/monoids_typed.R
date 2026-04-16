# Legacy standalone exploration script.
# It defines its own local Monoid/Tree types and does NOT use the fingertree
# package API (which now expects MeasureMonoid).
# Kept for historical learning notes.


library(lambda.r)

Function(f) %as% f
Identity(x) %as% x

### First up, a monoid is a data type containing a function
### (which should be associative binary) and an identity element:
Monoid(f, i) %as% list(f = f, i = i)

adder <- Monoid(Function(`+`), Identity(0))
multiplier <- Monoid(Function(`*`), Identity(1))
minner <- Monoid(Function(min), Identity(Inf))
maxxer <- Monoid(Function(max), Identity(-Inf))
catter <- Monoid(Function(paste0), Identity(""))
righter <- Monoid(Function(  function(x, y) {return(y)}  ), 
                             Identity("NoKey"))

### A "fold" is repeated application of the function from a monoid
### to a list of elements
### since the monoid is associative, it doesn't matter if it's e.g.
### (e1 + (e2 + (e3 + i))) or (((i + e1) + e2) + e3)
fold(l, m) %::% list : Monoid : .
fold(l, m) %as% {
  res <- m$i
  for(el in l) {
    res <- m$f(res, el)
  }
  return(res)
}

print(fold(list(4, 5, 2, 7), adder))
print(fold(list(4, 5, 2, 7), multiplier))
print(fold(list(4, 5, 2, 7), catter))
print(fold(list(4, 5, 2, 7), minner))
print(fold(list(4, 5, 2, 7), maxxer))
print(fold(list(4, 5, 2, 7), righter))



##############
### Monoids applied to trees: see https://apfelmus.nfshost.com/articles/monoid-fingertree.html
##############

Number(x) %as% x
Integer(x) %as% Number(x)
Float(x) %as% Number(x)



# Node is the generic that both Leaf and Tree will inherit from
# it stores arbitrary params from its inputs in a list
Tree(...) %::% ... : list
#Node(...) %::% ... : list
Tree(...) %as% list(...)
#Node(...) %as% list(...)

# I need a "nothing" type... or do I?
# as a bonus, using this as nothing won't cause a printout when returned but not used
Nothing() %as% invisible(NA)

# leaves have their primary element, and a tag which is equal to the element
Leaf(el, tag) %::% . : . : Tree
Leaf(el, tag) %as% Tree(el = el, tag = tag)

# trees have a left (Tree or Leaf), a right (Tree or Leaf) and a tag
# tagger is a function (Monoid) that computes the node's tag from the left and right tags
Branch(left, right, tagger) %::% Tree : Tree : Monoid : Tree
Branch(left, right, tagger) %as% {
  Tree(left = left, right = right, tag = tagger$f(left$tag, right$tag))
}



# so we can do t <- Nothing(); t <- insert_tree(t, Leaf(4))
insert_tree(t, leaf, tagger) %::% Nothing : Leaf : Monoid : Leaf
insert_tree(t, leaf, tagger) %as% { leaf }

insert_tree(t, leaf, tagger) %::% Leaf : Leaf : Monoid : Branch
insert_tree(t, leaf, tagger) %as% {
    Branch(t, leaf, tagger)
}

# this inserts elements at random locations (just testing monoid annotation in this script)
insert_tree(t, leaf, tagger) %::% Branch : Leaf : Monoid : Branch
insert_tree(t, leaf, tagger) %as% { 
  if(runif(1) < 0.5) {
    newleft <- insert_tree(t$left, leaf, tagger)
    return(Branch(newleft, t$right, tagger))
  } else {
    newright <- insert_tree(t$right, leaf, tagger)
    return(Branch(t$left, newright, tagger))
  }
}

# functions for counting the number of elements stored
count_nodes(t) %::% Nothing : numeric
count_nodes(t) %as% 0

count_nodes(t) %::% Leaf : numeric
count_nodes(t) %as% 1

count_nodes(t) %::% Tree : numeric
count_nodes(t) %as% { count_nodes(t$left) + count_nodes(t$right) + 1 }


t <- Nothing()
print(count_nodes(t))
t <- insert_tree(t, Leaf(3, 3), adder)
t <- insert_tree(t, Leaf(4, 4), adder)
t <- insert_tree(t, Leaf(2, 2), adder)
t <- insert_tree(t, Leaf(1, 1), adder)
print(count_nodes(t))


################ Drawing functions, let's draw some of these with turtlegraphics
library(TurtleGraphics)

turtle_getstate <- function() {
  state <- c(turtle_getpos(), turtle_getangle())
  return(state)
}

turtle_setstate <- function(state) {
  turtle_setpos(state[1], state[2])
  turtle_setangle(state[3])
}

turtle_text <- function(label, col = "black", fontsize = 8, readable = FALSE) {
  rot <- -1*turtle_getangle()
  if(readable) {rot <- 0}
  grid.text(label,
            turtle_getpos()[1],
            turtle_getpos()[2],
            rot = rot,
            default.units = "native",
            gp = gpar(fontsize = fontsize, col = col, lineheight = 0.7))
}




## If it's an empty tree, just draw that.
draw_tree(t) %::% Nothing : Nothing
draw_tree(t) %as% {
  turtle_text("~Empty Tree~", readable = TRUE)
  return(Nothing())
}

# If it's a leaf, we draw the tag in red, and the element in black
draw_tree(t) %::% Leaf : Nothing 
draw_tree(t) %as% {
  turtle_text(t$tag, col = "red", readable = TRUE)
  turtle_up()
  turtle_forward(3)
  turtle_down()
  turtle_text(t$el, readable = TRUE)
  return(Nothing())
}

# if it's n internal node, we we recursively draw each subtree, and then draw the label in red
draw_tree(t) %::% Tree : Nothing 
draw_tree(t) %as% {
  s <- turtle_getstate()
  turtle_right(15 + 3 * sqrt(count_nodes(t$left)))
  turtle_forward(10)
  draw_tree(t$left)
  turtle_setstate(s)
  
  #turtle_left(10 * sqrt(count_nodes(t$right)))
  turtle_left(15 + 3 * sqrt(count_nodes(t$right)))
  turtle_forward(10)
  draw_tree(t$right)
  turtle_setstate(s)
  turtle_text(t$tag, col = "red", readable = TRUE)  
  return(Nothing())
}



# a monoid search predicate is a function
predicate(f) %as% Function(f)

# # 
# search_in(t, p, m) %::% Leaf : Predicate : Monoid : .
# search_in(t, p, m) %as% {
#   if(p(t$tag)) {
#     return(t$el)
#   }
#   return(NA)
# }


# this just kicks the search off from the root
search_in(t, p, m) %::% Branch : Predicate : Monoid : .
search_in(t, p, m) %as% {
  if(p(t$tag)) {
    return(accumulate_search(t, m$i, p, m))
  }
  return(NA)
}

# first .: the identity element of a monoid, or the accumulated type, could be funky
# second .: element at the leaf, or NA
accumulate_search(l, acc, p, m) %::% Leaf : . : Predicate : Monoid : .
accumulate_search(l, acc, p, m) %as% {
  # we know it's FALSE for the incoming acc, that's how it got here
  if(p(m$f(acc, l$tag))) {
    return(l$el)
  }
  return(NA)
}

# second .: element at the leaf, or NA
accumulate_search(t, acc, p, m) %::% Branch : . : Predicate : Monoid : .
accumulate_search(t, acc, p, m) %as% {
  # we know it's FALSE for the incoming acc, that's how it got here
  if(p(m$f(acc, t$left$tag))) { # we need to consider everything up to this point to decide to branch left
    return(accumulate_search(t$left, acc, p, m)) # but when we do so, we don't bake-in the left branch (yet)
  }
  # else its rightward... we gotta add what's in the accumulator to the left we're skipping
  # if this is another branch, it'll recurse, if it's a node, it'll bottom out
  return(accumulate_search(t$right, m$f(acc, t$left$tag), p, m))
}



###### indexable sequence - build it and draw it

t1 <- Nothing()
set.seed(5)

for(randindex in sample(1:26, 15)) { 
  # prio-queue
  t1 <- insert_tree(t1, Leaf(letters[randindex], 1), adder)
}

turtle_init(mode = "clip")
turtle_hide()
turtle_setstate(c(50, 90, 180))
turtle_col("gray")

draw_tree(t1)



# search in it with the predicate function
# p <- function(tag) {tag > 4}
# p(3) => F
# p(5) => T
p <- function(tag) {tag >= 14}
print(search_in(t1, p, adder))





###### min-priority queue - build and draw
###### (use maxxer to get a max-priority queue)

t1 <- Nothing()
set.seed(5)

for(randindex in sample(1:26, 15)) { 
  # prio-queue
  t1 <- insert_tree(t1, Leaf(letters[randindex], randindex), minner) # the letters' index is the priority
}

turtle_init(mode = "clip")
turtle_hide()
turtle_setstate(c(50, 90, 180))
turtle_col("gray")

draw_tree(t1)



# the predicate function, search for the max priority in the tree and report the answer
# p <- function(tag) {tag > 4}
# p(3) => F
# p(5) => T
p <- function(tag) {tag == t1$tag}
print(search_in(t1, p, minner))






######
