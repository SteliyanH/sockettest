import Vapor

extension Droplet {
    func setupRoutes() throws {
      _ = GameController(drop: self)
    }
}
