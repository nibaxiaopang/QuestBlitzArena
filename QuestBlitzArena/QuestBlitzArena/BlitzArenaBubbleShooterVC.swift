//
//  BubbleShooterVC.swift
//  QuestBlitzArena
//
//  Created by jin fu on 2024/11/18.
//

import UIKit
import AVFoundation

class BlitzArenaBubbleShooterVC: UIViewController {
    
    // MARK: - UI Elements
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var gridView: UIView!
    @IBOutlet weak var shooterView: UIView!
    @IBOutlet weak var shooterBubble: UIButton!
    
    // MARK: - Properties
    var score = 0
    var bubbleGrid: [[UIButton?]] = []
    var bubbleColors: [UIColor] = [.red, .blue, .green, .yellow]
    var currentLevel = 1
    var bubbleDiameter: CGFloat = 0
    var shootingBubbleColor: UIColor = .red
    var aimAngle: CGFloat = CGFloat.pi / 2
    var aimLineLayer: CAShapeLayer?
    let popRange: CGFloat = 25.0
    
    var fireSound: AVAudioPlayer?
    var popSound: AVAudioPlayer?
    var collisionLink: CADisplayLink?
    var shotBubble: UIButton?
    
    // MARK: - Firing Speed and Delay
    
    var lastShotTime: TimeInterval = 0
    let fireDelay: TimeInterval = 1.0
    let slowFireSpeed: CGFloat = 5.0
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupGame(level: currentLevel)
        showRulesAlert()
        // Add a pan gesture recognizer to adjust the shooting angle
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(adjustAim(_:)))
        shooterView.addGestureRecognizer(panGesture)
        
        // Load sound effects
        loadSoundEffects()
    }
    
    // MARK: - Game Setup
    private func setupGame(level: Int) {
        setupBubbleGrid()
        updateScoreLabel()
        setupShooterBubble()
    }
    
    private func setupBubbleGrid() {
        gridView.subviews.forEach { $0.removeFromSuperview() }
        bubbleGrid = []
        
        let bubbleSpacing: CGFloat = 5
        let columns = 15
        let rows = 6
        
        let totalHorizontalSpacing = bubbleSpacing * CGFloat(columns + 1)
        let totalVerticalSpacing = bubbleSpacing * CGFloat(rows + 1)
        
        let availableWidth = gridView.frame.width - totalHorizontalSpacing
        let availableHeight = gridView.frame.height - totalVerticalSpacing
        bubbleDiameter = min(availableWidth / CGFloat(columns), availableHeight / CGFloat(rows))
        
        for row in 0..<rows {
            var rowArray: [UIButton?] = []
            for col in 0..<columns {
                let xPosition = bubbleSpacing + CGFloat(col) * (bubbleDiameter + bubbleSpacing)
                let yPosition = bubbleSpacing + CGFloat(row) * (bubbleDiameter + bubbleSpacing)
                
                let bubbleButton = UIButton(frame: CGRect(x: xPosition, y: yPosition, width: bubbleDiameter, height: bubbleDiameter))
                bubbleButton.backgroundColor = bubbleColors.randomElement()
                bubbleButton.layer.cornerRadius = bubbleDiameter / 2
                bubbleButton.clipsToBounds = true
                gridView.addSubview(bubbleButton)
                rowArray.append(bubbleButton)
            }
            bubbleGrid.append(rowArray)
        }
    }
    
    func historySaved() {
        
        let historyData: [String: Any] = ["right": score]
        
        var historyArray = UserDefaults.standard.array(forKey: "history") as? [[String: Any]] ?? []
        historyArray.append(historyData)
        UserDefaults.standard.set(historyArray, forKey: "history")
    }
    
    private func setupShooterBubble() {
        shootingBubbleColor = bubbleColors.randomElement() ?? .red
        shooterBubble.backgroundColor = shootingBubbleColor
        shooterBubble.layer.cornerRadius = shooterBubble.frame.height / 2
    }
    
    private func updateScoreLabel() {
        scoreLabel.text = "Score: \(score)"
    }
    
    // MARK: - Aim Adjustment
    @objc private func adjustAim(_ gesture: UIPanGestureRecognizer) {
        let location = gesture.location(in: view)
        let dx = location.x - shooterBubble.center.x
        let dy = shooterBubble.center.y - location.y
        aimAngle = atan2(dy, dx)
        
        shooterBubble.transform = CGAffineTransform(rotationAngle: aimAngle - CGFloat.pi / 2)
        drawAimLine()
        
        if gesture.state == .ended {
            gesture.setTranslation(.zero, in: view)
        }
    }
    
    private func drawAimLine() {
        aimLineLayer?.removeFromSuperlayer()
        
        let startPoint = shooterBubble.center
        let distance: CGFloat = 300
        let endPoint = CGPoint(x: startPoint.x + distance * cos(aimAngle),
                               y: startPoint.y - distance * sin(aimAngle))
        
        let path = UIBezierPath()
        path.move(to: startPoint)
        path.addLine(to: endPoint)
        
        let lineLayer = CAShapeLayer()
        lineLayer.path = path.cgPath
        lineLayer.strokeColor = UIColor.white.withAlphaComponent(0.7).cgColor
        lineLayer.lineWidth = 2.0
        lineLayer.lineDashPattern = [4, 2]
        
        view.layer.addSublayer(lineLayer)
        aimLineLayer = lineLayer
    }
    
    // MARK: - Actions
    @IBAction func shootBubble() {
        let currentTime = Date().timeIntervalSince1970
        if currentTime - lastShotTime < fireDelay {
            return  // Don't shoot again if the delay hasn't passed
        }
        
        lastShotTime = currentTime  // Update last shot time
        aimLineLayer?.removeFromSuperlayer()
        playSound(fireSound)

        shotBubble = UIButton(frame: shooterBubble.frame)
        shotBubble?.backgroundColor = shooterBubble.backgroundColor
        shotBubble?.layer.cornerRadius = shooterBubble.layer.cornerRadius
        if let shotBubble = shotBubble {
            view.addSubview(shotBubble)
        }
        
        shootingBubbleColor = bubbleColors.randomElement() ?? .red
        shooterBubble.backgroundColor = shootingBubbleColor
        
        // Start collision detection with CADisplayLink
        collisionLink = CADisplayLink(target: self, selector: #selector(updateShotBubblePosition))
        collisionLink?.add(to: .main, forMode: .default)
    }
    
    // Continuous collision detection and animation for the shot bubble
    @objc private func updateShotBubblePosition() {
        guard let shotBubble = shotBubble else {
            collisionLink?.invalidate()
            return
        }
        
        let moveDistance: CGFloat = slowFireSpeed  // Slow down the bubble's movement
        shotBubble.center.x += moveDistance * cos(aimAngle)
        shotBubble.center.y -= moveDistance * sin(aimAngle)
        
        // Check for collision with bubbles in the grid
        if checkBubbleCollision(shotBubble) {
            removeShotBubble()
        } else if !view.bounds.contains(shotBubble.center) {
            // Remove the shot bubble if it goes out of bounds
            removeShotBubble()
        }
    }
    
    private func checkBubbleCollision(_ shotBubble: UIButton) -> Bool {
        guard let shotColor = shotBubble.backgroundColor else { return false }
        
        for row in 0..<bubbleGrid.count {
            for col in 0..<bubbleGrid[row].count {
                if let gridBubble = bubbleGrid[row][col], gridBubble.backgroundColor == shotColor {
                    let distance = hypot(gridBubble.center.x - shotBubble.center.x, gridBubble.center.y - shotBubble.center.y)
                    
                    if distance <= (bubbleDiameter / 2 + popRange) {
                        playSound(popSound)
                        popConnectedBubblesBFS(fromRow: row, col: col, color: shotColor)
                        return true
                    }
                }
            }
        }
        return false
    }
    
    private func removeShotBubble() {
        shotBubble?.removeFromSuperview()
        shotBubble = nil
        collisionLink?.invalidate()
        
        checkGameOver()  // Check if game over after each shot
    }
    
    private func popConnectedBubblesBFS(fromRow row: Int, col: Int, color: UIColor) {
        var queue = [(row, col)]
        var visited = Set<String>()
        visited.insert("\(row),\(col)")
        
        while !queue.isEmpty {
            let (currentRow, currentCol) = queue.removeFirst()
            
            if let bubble = bubbleGrid[currentRow][currentCol], bubble.backgroundColor == color {
                bubble.removeFromSuperview()
                bubbleGrid[currentRow][currentCol] = nil
                score += 10
                updateScoreLabel()
            }
            
            let directions = [(0, 1), (1, 0), (0, -1), (-1, 0), (1, 1), (-1, -1), (1, -1), (-1, 1)]
            for (dRow, dCol) in directions {
                let newRow = currentRow + dRow
                let newCol = currentCol + dCol
                let key = "\(newRow),\(newCol)"
                
                if newRow >= 0, newRow < bubbleGrid.count, newCol >= 0, newCol < bubbleGrid[newRow].count, !visited.contains(key),
                   let neighborBubble = bubbleGrid[newRow][newCol], neighborBubble.backgroundColor == color {
                    queue.append((newRow, newCol))
                    visited.insert(key)
                }
            }
        }
    }
    
    // MARK: - Game Over Check
    private func checkGameOver() {
        // Check if all bubbles are popped (empty grid)
        let isGridEmpty = bubbleGrid.allSatisfy { row in
            row.allSatisfy { $0 == nil }
        }
        
        if isGridEmpty {
            // Display game over alert and option to restart
            historySaved()
            let alert = UIAlertController(title: "Game Over!", message: "Your final score is \(score).", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Restart", style: .default, handler: { _ in
                self.restartGame()
            }))
            present(alert, animated: true, completion: nil)
        }
    }
    
    private func restartGame() {
        score = 0
        updateScoreLabel()
        currentLevel = 1
        setupGame(level: currentLevel)
    }
    
    // MARK: - Sound Effects
    private func loadSoundEffects() {
        fireSound = loadSound(named: "fire")
        popSound = loadSound(named: "pop")
    }
    
    private func loadSound(named: String) -> AVAudioPlayer? {
        guard let url = Bundle.main.url(forResource: named, withExtension: "mp3") else { return nil }
        return try? AVAudioPlayer(contentsOf: url)
    }
    
    private func playSound(_ sound: AVAudioPlayer?) {
        sound?.stop()
        sound?.currentTime = 0
        sound?.play()
    }
    private func showRulesAlert() {
           let rules = """
           Welcome to Bubble Shooter!

           - Aim and shoot bubbles to match colors.
           - Bubbles of the same color will pop and increase your score.
           - Clear all bubbles to win the game.

           Good luck and have fun!
           """
           
           let alert = UIAlertController(title: "Game Rules", message: rules, preferredStyle: .alert)
           let startAction = UIAlertAction(title: "Start Game", style: .default) { _ in
               self.setupGame(level: self.currentLevel)
           }
           
           alert.addAction(startAction)
           present(alert, animated: true, completion: nil)
       }
}
