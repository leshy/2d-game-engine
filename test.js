
a = function () {
    console.log ('a init')
    this.bla = 3
}

a.prototype.k = function () { return 666 }

b = function () {
    console.log ('b init')
    this.bla = 6
}

b.prototype = a.prototype

x1 = new b()

console.log(x1.bla,x1.k())
