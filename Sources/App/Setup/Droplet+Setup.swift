@_exported import Vapor

let game = Game()

extension Droplet {
    public func setup() throws {
//        try setupRoutes()
      
      socket("game") { (req, socket) in
        var scribPlayer: String? = nil
        
        try background {
          while socket.state == .open {
            try? socket.ping()
            self.console.wait(seconds: 5)
          }
        }
        
        socket.onText = { socket, message in
          let json = try JSON(bytes: Array(message.utf8))
          
          print(json)
          
          guard let msgType = json.object?["command"]?.string, let player = json.object?["player"]?.string else {
            return
          }
          
          if msgType.equals(caseInsensitive: "connect") {
            scribPlayer = player
            game.connections[player] = socket
            
            let response = try JSON(node: [
              "command":"connected",
              "username": player
              ])
            
            for (_, connection) in game.connections {
              try connection.send(response)
            }
          } else if (msgType.equals(caseInsensitive: "clear")) {
            for (_, connection) in game.connections {
              try connection.send(json)
            }
          } else {
            
            for (scrib, connection) in game.connections {
              if (!scrib.equals(caseInsensitive: player)) {
                try connection.send(json)
              }
            }
          }
        }
        
        socket.onClose = { ws, _, _, _ in
          guard let player = scribPlayer else {
            return
          }
          
          let disconn = try JSON(node: [
            "command": "disconnect",
            "username": player
            ])
          
          for (remote, connection) in game.connections {
            if (!remote.equals(caseInsensitive: player)) {
              try connection.send(disconn)
            }
          }
          
          game.connections.removeValue(forKey: player)
        }
      }
    }
}
