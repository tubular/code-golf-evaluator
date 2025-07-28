#! /usr/bin/env -S scala
object HelloWorld extends App {
  io.Source.stdin.getLines().foreach((i)=>{println("hello, "+i)})
}
