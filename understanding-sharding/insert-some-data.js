var randomName = function() {
  // Base 36 uses letters and digits to represent a number
  // substring to only 6 chars
  return (Math.random()+1).toString(36).substring(2,8)
}

// adding about 200 bytes each time
for (var i = 0; i <= 5000; ++i) {
  db.test.insert({
      x: randomName(),
      y: "11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111"
  });
}

