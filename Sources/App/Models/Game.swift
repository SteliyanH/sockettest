//
//  Game.swift
//  SocketTestPackageDescription
//
//  Created by Steliyan H. on 29.03.18.
//

import Vapor

class Game {
  var connections: [String: WebSocket]
  
  func bot(_ message: String) {
    send(player: "Bot", answer: message)
  }
  
  func send(player: String, answer: String) {
    
    let messageNode: [String: NodeRepresentable] = [
      "player": player,
      "answer": answer
    ]
    
    guard let json = try? JSON(node: messageNode) else {
      return
    }
    
    for (username, socket) in connections {
      guard username != player else {
        continue
      }
      
      try? socket.send(json)
    }
  }
  
  init() {
    connections = [:]
  }
}
