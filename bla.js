(function() {
  var maintain, start;
  start = function(processes, n) {};
  maintain = function(processes, n) {
    var running;
    running = [];
    return _.times(n, function() {
      var proc;
      proc = processes.pop();
      running.push(proc);
      return proc.start();
    });
  };
}).call(this);
