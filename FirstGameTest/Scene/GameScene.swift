//
//  GameScene.swift
//  FirstGameTest
//
//  Created by Jonas Liermann on 01.03.21.
//

import SpriteKit
import AVFoundation

enum DifficultLevel {
    case easy
    case normal
    case hard
    }

struct PhysicsCategorie {
    static let none: UInt32 = 0
    static let enemy: UInt32 = 0b1 // binäre 1
    static let shoot: UInt32 = 0b10 // binäre 2
    
}


class GameScene: SKScene, SKPhysicsContactDelegate {
 
    let player = SKSpriteNode(imageNamed: "Spaceship")
    let gameLabel = SKLabelNode(text: "Welcome")
    var scoreLabel = SKLabelNode(text: "0")
    var gameScore = 0
    let highScoreLabel = SKLabelNode(text: "Highscore:")
    
    // for saving highscore
    var defaults = UserDefaults.standard
    
        
    let background1 = SKSpriteNode(imageNamed: "background_1")
    let background2 = SKSpriteNode(imageNamed: "background_2")
    
    let explosionSound = SKAction.playSoundFileNamed("explosion", waitForCompletion: false)
    let shootSound = SKAction.playSoundFileNamed("LaserShot", waitForCompletion: false)
    
    var audioPlayer = AVAudioPlayer()
    var backgroundAudio: URL?
    
    var spawntimer = Timer()
    

    override func didMove(to view: SKView) {
        
        
        
        self.physicsWorld.contactDelegate = self
        
        player.position = CGPoint(x: self.size.width / 2, y: self.size.height / 2)
        player.setScale(0.5)
        self.addChild(player)
        
        gameLabel.fontSize = 80
        gameLabel.position = CGPoint(x: self.size.width / 2, y: self.size.height - 600)
        self.addChild(gameLabel)
        
        scoreLabel.fontSize = 60
        scoreLabel.position = CGPoint(x: self.size.width / 2, y: self.size.height - 600 - gameLabel.fontSize)
        scoreLabel.isHidden = true
        self.addChild(scoreLabel)
        
        highScoreLabel.fontSize = 50
        highScoreLabel.position = CGPoint(x: 200, y: 460)
        self.addChild(highScoreLabel)
      
        createEnemy()
        addBackground()
        loadHighScore()
       
        //MARK: - difficultLevel
        
        let difficultLevel: DifficultLevel = DifficultLevel.hard
        
        switch difficultLevel {
        case .easy: Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(GameScene.createEnemy), userInfo: nil, repeats: true)
        case .normal: Timer.scheduledTimer(timeInterval: 4, target: self, selector: #selector(GameScene.createEnemy), userInfo: nil, repeats: true)
        case .hard: Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(GameScene.createEnemy), userInfo: nil, repeats: true)
            }
        
        // MARK: - play sound
        
        backgroundAudio = Bundle.main.url(forResource: "Steamtech-Mayhem", withExtension: "mp3")
        
        do {
            guard let audio = backgroundAudio else {
                return
                }
        audioPlayer = try AVAudioPlayer(contentsOf: audio)
        } catch {
        print("keine Musik gefunden.")
            }
        
        audioPlayer.numberOfLoops = -1 // play sound
        audioPlayer.prepareToPlay()
        audioPlayer.play()
       
    }
    
    // MARK: - spaceship moves
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        shoot()
        player.run(shootSound)
        
       for touch in touches {
            shoot()
            let location = touch.location(in: self)
            player.position = location
             
            }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            player.position = location
    }
    
    }
    // MARK: - shoot
    
        func shoot() {
        let bullet = SKSpriteNode(imageNamed: "bullet_red")
        bullet.position = player.position
        bullet.zPosition = 3
        self.addChild(bullet)
            
        // Physics
        bullet.physicsBody = SKPhysicsBody(texture: bullet.texture!, size: bullet.size)
        bullet.physicsBody?.affectedByGravity = false
        bullet.physicsBody?.categoryBitMask = PhysicsCategorie.shoot
        bullet.physicsBody?.contactTestBitMask = PhysicsCategorie.enemy
        bullet.physicsBody?.collisionBitMask = PhysicsCategorie.none
            
            
        // Actions
        let move = SKAction.moveTo(y: self.size.height + bullet.frame.size.height, duration: 1)
        let delete = SKAction.removeFromParent()
        bullet.run(SKAction.sequence([move, delete]))
    }
    // MARK: - create enemy
    @objc func createEnemy() {
        
        var enemyArray: [SKTexture] = []
        
        for index in 1...8 {
            enemyArray.append(SKTexture(imageNamed: "\(index)"))
            }
        
        let enemy = SKSpriteNode(imageNamed: "spaceship_enemy_start")
        // Gegner größe
        enemy.setScale(0.9)
        enemy.position = CGPoint(x: CGFloat(arc4random_uniform(UInt32(self.size.width))), y: self.size.height + enemy.size.height)
        enemy.zPosition = 1
        enemy.zRotation = CGFloat((180*Double.pi) / 180)
        
        self.addChild(enemy)
        
        // Physics
        enemy.physicsBody = SKPhysicsBody(texture: enemy.texture!, size: enemy.size)
        enemy.physicsBody?.isDynamic = false
        enemy.physicsBody?.categoryBitMask = PhysicsCategorie.enemy
        enemy.physicsBody?.contactTestBitMask = PhysicsCategorie.shoot
        enemy.physicsBody?.collisionBitMask = PhysicsCategorie.none
        
        
        // Actions
        let move = SKAction.moveTo(y: -enemy.size.height, duration: 5)
        let delete = SKAction.removeFromParent()
        
        enemy.run(SKAction.sequence([move, delete]))
    }
    // MARK: - Background view
    
    func addBackground() {
        background1.anchorPoint = CGPoint.zero
        background1.position.x = 0
        background1.position.y = background1.size.height - 5
        background1.size = self.size
        background1.zPosition = -1
        self.addChild(background1)
        
        background2.anchorPoint = CGPoint.zero
        background2.position.x = 0
        background2.position.y = 0
        background2.size = self.size
        background2.zPosition = -1
        self.addChild(background2)
        }
    
    
    func didBegin(_ contact: SKPhysicsContact) {
        var firstBody = SKPhysicsBody()
        var secBody = SKPhysicsBody()
        
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secBody = contact.bodyB
        }else {
            firstBody = contact.bodyB
            secBody = contact.bodyA
            }
        
        if firstBody.categoryBitMask == PhysicsCategorie.enemy && secBody.categoryBitMask == PhysicsCategorie.shoot {
            
            guard let node1 = firstBody.node else {
                print("nicht gefunden")
                return
            }
            
            guard let node2 = secBody.node else {
                print("nicht gefunden")
                return
            }
            
            shootEnemy(shoot: node2 as! SKSpriteNode, enemy: node1 as! SKSpriteNode)
    }
    }
    
    func shootEnemy(shoot: SKSpriteNode, enemy: SKSpriteNode) {
        let explosion = SKSpriteNode(imageNamed: "explosion")
        explosion.position = shoot.position
        explosion.zPosition = 3
        explosion.setScale(0)
        self.addChild(explosion)
        
        let scaleIn = SKAction.scaleY(to: 1, duration: 2)
        let fadeOut = SKAction.fadeOut(withDuration: 2)
        let delete = SKAction.removeFromParent()
        
        let exploded = SKAction.sequence([explosionSound,scaleIn, fadeOut, delete])
        explosion.run(exploded)
        
        shoot.removeFromParent()
        enemy.removeFromParent()
        
        gameLabel.text = "Score"
        
        gameScore += 1
        scoreLabel.isHidden = false
        scoreLabel.text = "\(gameScore)"
      
        
        
        }
    // MARK: - userDefaults
    
    func saveHighScore(){
        defaults.set("\(gameScore)", forKey: "HIGHSCORE")
    }
    
    func loadHighScore() {
        let highScore = defaults.integer(forKey: "HIGHSCORE")
        highScoreLabel.text = "Highscore: \(highScore)"
        }
  
    // MARK: - Background update
    
    override func update(_ currentTime: TimeInterval) {
        background1.position.y -= 5
        background2.position.y -= 5
        
        if background1.position.y < -background1.size.height {
            background1.position.y = background2.position.y + background2.size.height
        }
        if background2.position.y < -background2.size.height {
            background2.position.y = background1.position.y + background1.size.height
        }
        
      saveHighScore()
    
       
    }
    
   
    
    
    
}


