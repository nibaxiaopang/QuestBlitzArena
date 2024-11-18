//
//  ChainReactionVC.swift
//  QuestBlitzArena
//
//  Created by jin fu on 2024/11/18.
//

import UIKit

class BlitzArenaChainReactionVC: UIViewController {

    // MARK: - UI Elements
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var gridView: UIView!
    
    // MARK: - Properties
    var score = 0
    var bubbleGrid: [[UIButton?]] = []
    var bubbleColors: [UIColor] = [.red, .blue, .green, .yellow, .purple]
    var bubbleDiameter: CGFloat = 0

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupGame()
        showRulesAlert()
     }
  
    private func showRulesAlert() {
           let rules = """
           Welcome to Chain Blast!
           
           Tap on a bubble to start a chain reaction.
           All connected bubbles of the same color will pop, increasing your score.
           
           The goal is to clear all bubbles for maximum points.
           
           Good luck and have fun!
           """
           
           let alert = UIAlertController(title: "Game Rules", message: rules, preferredStyle: .alert)
           let startAction = UIAlertAction(title: "Start Game", style: .default) { _ in
               self.setupGame()
           }
           
           alert.addAction(startAction)
           present(alert, animated: true, completion: nil)
       }
    // MARK: - Game Setup
    private func setupGame() {
        setupBubbleGrid()
        updateScoreLabel()
    }

    private func setupBubbleGrid() {
        gridView.subviews.forEach { $0.removeFromSuperview() }
        bubbleGrid = []

        let bubbleSpacing: CGFloat = 5
        let columns = 15
        let rows = 10

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
                bubbleButton.addTarget(self, action: #selector(bubbleTapped(_:)), for: .touchUpInside)
                gridView.addSubview(bubbleButton)
                rowArray.append(bubbleButton)
            }
            bubbleGrid.append(rowArray)
        }
    }

    private func updateScoreLabel() {
        scoreLabel.text = "Score: \(score)"
    }

    // MARK: - Game Logic
    @objc private func bubbleTapped(_ sender: UIButton) {
        guard let (startRow, startCol) = findBubblePosition(sender) else { return }
        let color = sender.backgroundColor ?? .clear
        
        // Begin chain reaction from the tapped bubble
        let poppedCount = popConnectedBubbles(fromRow: startRow, col: startCol, color: color)
        
         score += poppedCount * 10
        updateScoreLabel()
        
         checkGameOver()
    }

    private func findBubblePosition(_ bubble: UIButton) -> (Int, Int)? {
        for row in 0..<bubbleGrid.count {
            for col in 0..<bubbleGrid[row].count {
                if bubbleGrid[row][col] == bubble {
                    return (row, col)
                }
            }
        }
        return nil
    }

    private func popConnectedBubbles(fromRow row: Int, col: Int, color: UIColor) -> Int {
        var queue = [(row, col)]
        var visited = Set<String>()
        visited.insert("\(row),\(col)")
        
        var poppedCount = 0
        
        while !queue.isEmpty {
            let (currentRow, currentCol) = queue.removeFirst()
            
            // Remove bubble from grid and UI
            if let bubble = bubbleGrid[currentRow][currentCol], bubble.backgroundColor == color {
                bubble.removeFromSuperview()
                bubbleGrid[currentRow][currentCol] = nil
                poppedCount += 1
            }
            
            // Check all four directions (up, down, left, right)
            let directions = [(0, 1), (1, 0), (0, -1), (-1, 0)]
            for (dRow, dCol) in directions {
                let newRow = currentRow + dRow
                let newCol = currentCol + dCol
                let key = "\(newRow),\(newCol)"
                
                // Check bounds and whether this position has been visited
                if newRow >= 0, newRow < bubbleGrid.count, newCol >= 0, newCol < bubbleGrid[newRow].count, !visited.contains(key) {
                    if let adjacentBubble = bubbleGrid[newRow][newCol], adjacentBubble.backgroundColor == color {
                        queue.append((newRow, newCol))
                        visited.insert(key)
                    }
                }
            }
        }
        
        return poppedCount
    }

    // MARK: - Game Over Check
    private func checkGameOver() {
        // Check if all bubbles are popped (empty grid)
        let isGridEmpty = bubbleGrid.allSatisfy { row in
            row.allSatisfy { $0 == nil }
        }
        
        if isGridEmpty {
            // Display game-over alert and option to restart
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
        setupGame()
    }
}
