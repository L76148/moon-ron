///|
let config : Config = Config::{
  name: "moon-mon",
  version: "0.1.0",
  ports: [8080, 8081],
  limits: { "cpu": 4, "memory": 1024U },
  owner: Some(Point::{ x: 1, y: 2, }),
  banner: "MON reads data written the way MoonBit writes its literals.",
  mask: b"\x0f\xf0",
  total: 9000000000L,
  locked: true,
}
