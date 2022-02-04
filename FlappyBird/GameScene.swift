//
//  GameScene.swift
//  FlappyBird
//
//  Created by ryouta.araki4 on 2022/01/31.
//

import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {

    var scrollNode:SKNode!
    var wallNode:SKNode!    // 追加
    var bird:SKSpriteNode!    // 追加
    var ringoNode:SKNode!
    var ringo:SKSpriteNode!
    
    // 衝突判定カテゴリー ↓追加
    let birdCategory: UInt32 = 1 << 0       // 0...00001
    let groundCategory: UInt32 = 1 << 1     // 0...00010
    let wallCategory: UInt32 = 1 << 2       // 0...00100
    let scoreCategory: UInt32 = 1 << 3      // 0...01000
    let ringoCategory: UInt32 = 1 << 4

    // スコア用
    var score = 0  // ←追加
    var ringoScore = 0  // ←追加
    var scoreLabelNode:SKLabelNode!    // ←追加
    var bestScoreLabelNode:SKLabelNode!    // ←追加
    var ringoScoreLabelNode:SKLabelNode!
    let userDefaults:UserDefaults = UserDefaults.standard    // 追加
    
    let getRingoSound = SKAction.playSoundFileNamed("paku.mp3", waitForCompletion: true)
    let getNashiSound = SKAction.playSoundFileNamed("kira.mp3", waitForCompletion: true)
    
    // SKView上にシーンが表示されたときに呼ばれるメソッド
    override func didMove(to view: SKView) {

        // 重力を設定
        physicsWorld.gravity = CGVector(dx: 0, dy: -4)    // ←追加
        physicsWorld.contactDelegate = self // ←追加
        
        // 背景色を設定
        backgroundColor = UIColor(red: 0.15, green: 0.75, blue: 0.90, alpha: 1)

        // スクロールするスプライトの親ノード
        scrollNode = SKNode()
        addChild(scrollNode)

        // 壁用のノード
        wallNode = SKNode()   // 追加
        scrollNode.addChild(wallNode)   // 追加
        
        ringoNode = SKNode()
        scrollNode.addChild(ringoNode)
        
        // 各種スプライトを生成する処理をメソッドに分割
        setupGround()
        setupCloud()
        setupWall()   // 追加
        setupBird()   // 追加
        setupScoreLabel()   // 追加
        setupRingo()
    }

    func setupGround() {
        // 地面の画像を読み込む
        let groundTexture = SKTexture(imageNamed: "ground")
        groundTexture.filteringMode = .nearest

        // 必要な枚数を計算
        let needNumber = Int(self.frame.size.width / groundTexture.size().width) + 2

        // スクロールするアクションを作成
        // 左方向に画像一枚分スクロールさせるアクション
        let moveGround = SKAction.moveBy(x: -groundTexture.size().width, y: 0, duration: 5)

        // 元の位置に戻すアクション
        let resetGround = SKAction.moveBy(x: groundTexture.size().width, y: 0, duration: 0)

        // 左にスクロール->元の位置->左にスクロールと無限に繰り返すアクション
        let repeatScrollGround = SKAction.repeatForever(SKAction.sequence([moveGround, resetGround]))

        // groundのスプライトを配置する
        for i in 0..<needNumber {
            let sprite = SKSpriteNode(texture: groundTexture)

            // スプライトの表示する位置を指定する
            sprite.position = CGPoint(
                x: groundTexture.size().width / 2  + groundTexture.size().width * CGFloat(i),
                y: groundTexture.size().height / 2
            )

            // スプライトにアクションを設定する
            sprite.run(repeatScrollGround)

            // スプライトに物理演算を設定する
            sprite.physicsBody = SKPhysicsBody(rectangleOf: groundTexture.size())   // ←追加

            // 衝突のカテゴリー設定
            sprite.physicsBody?.categoryBitMask = groundCategory    // ←追加
            
            // 衝突の時に動かないように設定する
            sprite.physicsBody?.isDynamic = false   // ←追加
            
            // スプライトを追加する
            scrollNode.addChild(sprite)
        }
    }

    func setupCloud() {
        // 雲の画像を読み込む
        let cloudTexture = SKTexture(imageNamed: "cloud")
        cloudTexture.filteringMode = .nearest

        // 必要な枚数を計算
        let needCloudNumber = Int(self.frame.size.width / cloudTexture.size().width) + 2

        // スクロールするアクションを作成
        // 左方向に画像一枚分スクロールさせるアクション
        let moveCloud = SKAction.moveBy(x: -cloudTexture.size().width, y: 0, duration: 20)

        // 元の位置に戻すアクション
        let resetCloud = SKAction.moveBy(x: cloudTexture.size().width, y: 0, duration: 0)

        // 左にスクロール->元の位置->左にスクロールと無限に繰り返すアクション
        let repeatScrollCloud = SKAction.repeatForever(SKAction.sequence([moveCloud, resetCloud]))

        // スプライトを配置する
        for i in 0..<needCloudNumber {
            let sprite = SKSpriteNode(texture: cloudTexture)
            sprite.zPosition = -100 // 一番後ろになるようにする

            // スプライトの表示する位置を指定する
            sprite.position = CGPoint(
                x: cloudTexture.size().width / 2 + cloudTexture.size().width * CGFloat(i),
                y: self.size.height - cloudTexture.size().height / 2
            )

            // スプライトにアニメーションを設定する
            sprite.run(repeatScrollCloud)

            // スプライトを追加する
            scrollNode.addChild(sprite)
        }
    }
    
    func setupWall() {
            // 壁の画像を読み込む
            let wallTexture = SKTexture(imageNamed: "wall")
            wallTexture.filteringMode = .linear
            // 移動する距離を計算
            let movingDistance = self.frame.size.width + wallTexture.size().width
            // 画面外まで移動するアクションを作成
            let moveWall = SKAction.moveBy(x: -movingDistance, y: 0, duration:4)
            // 自身を取り除くアクションを作成
            let removeWall = SKAction.removeFromParent()
            // 2つのアニメーションを順に実行するアクションを作成
            let wallAnimation = SKAction.sequence([moveWall, removeWall])
            // 鳥の画像サイズを取得
            let birdSize = SKTexture(imageNamed: "bird_a").size()
            // 鳥が通り抜ける隙間の大きさを鳥のサイズの4倍とする
            let slit_length = birdSize.height * 4
            // 隙間位置の上下の振れ幅を60ptとする
            let random_y_range: CGFloat = 60
            // 空の中央位置(y座標)を取得
            let groundSize = SKTexture(imageNamed: "ground").size()
            let sky_center_y = groundSize.height + (self.frame.size.height - groundSize.height) / 2

            // 空の中央位置を基準にして下の壁の中央位置を取得
            let under_wall_center_y = sky_center_y - slit_length / 2 - wallTexture.size().height / 2
            // 壁を生成するアクションを作成
            let createWallAnimation = SKAction.run({
                // 壁関連のノードを乗せるノードを作成
                let wall = SKNode()
                wall.position = CGPoint(x: self.frame.size.width + wallTexture.size().width / 2, y: 0)
                wall.zPosition = -50 // 雲より手前、地面より奥
                // -random_y_range〜random_y_rangeの範囲のランダム値を生成
                let random_y = CGFloat.random(in: -random_y_range...random_y_range)

                // 下の壁の中央位置にランダム値を足して、下の壁の表示位置を決定
                let under_wall_y = under_wall_center_y + random_y
                // 下側の壁を作成
                let under = SKSpriteNode(texture: wallTexture)
                under.position = CGPoint(x: 0, y: under_wall_y)
                
                // スプライトに物理演算を設定する
                under.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())    // ←追加
                // 衝突の時に動かないように設定する
                under.physicsBody?.isDynamic = false    // ←追加
                
                wall.addChild(under)
                
                // 上側の壁を作成
                let upper = SKSpriteNode(texture: wallTexture)
                upper.position = CGPoint(x: 0, y: under_wall_y + wallTexture.size().height + slit_length)
                
                // スプライトに物理演算を設定する
                upper.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())    // ←追加
                // 衝突の時に動かないように設定する
                upper.physicsBody?.isDynamic = false    // ←追加
                
                wall.addChild(upper)
                
                // スコアアップ用のノード --- ここから ---
                let scoreNode = SKNode()
                scoreNode.position = CGPoint(x: upper.size.width + birdSize.width / 2, y: self.frame.height / 2)
                scoreNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: upper.size.width, height: self.frame.size.height))
                scoreNode.physicsBody?.isDynamic = false
                scoreNode.physicsBody?.categoryBitMask = self.scoreCategory
                scoreNode.physicsBody?.contactTestBitMask = self.birdCategory
                wall.addChild(scoreNode)
                // --- ここまで追加 ---
                
                wall.run(wallAnimation)
                self.wallNode.addChild(wall)
            })
            // 次の壁作成までの時間待ちのアクションを作成
            let waitAnimation = SKAction.wait(forDuration: 2)
            // 壁を作成->時間待ち->壁を作成を無限に繰り返すアクションを作成
            let repeatForeverAnimation = SKAction.repeatForever(SKAction.sequence([createWallAnimation, waitAnimation]))
            wallNode.run(repeatForeverAnimation)
        }
    
    // 以下追加
    func setupBird() {
        // 鳥の画像を2種類読み込む
        let birdTextureA = SKTexture(imageNamed: "bird_a")
        birdTextureA.filteringMode = .linear
        let birdTextureB = SKTexture(imageNamed: "bird_b")
        birdTextureB.filteringMode = .linear

        // 2種類のテクスチャを交互に変更するアニメーションを作成
        let texturesAnimation = SKAction.animate(with: [birdTextureA, birdTextureB], timePerFrame: 0.2)
        let flap = SKAction.repeatForever(texturesAnimation)

        // スプライトを作成
        bird = SKSpriteNode(texture: birdTextureA)
        bird.position = CGPoint(x: self.frame.size.width * 0.2, y:self.frame.size.height * 0.7)

        // 物理演算を設定
        bird.physicsBody = SKPhysicsBody(circleOfRadius: bird.size.height / 2)    // ←追加
        
        // 衝突した時に回転させない
        bird.physicsBody?.allowsRotation = false    // ←追加

        // 衝突のカテゴリー設定
        bird.physicsBody?.categoryBitMask = birdCategory    // ←追加
        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory | ringoCategory   // ←追加
        bird.physicsBody?.contactTestBitMask = groundCategory | wallCategory | ringoCategory   // ←追加

        // アニメーションを設定
        bird.run(flap)

        // スプライトを追加する
        addChild(bird)
    }
    
    // SKPhysicsContactDelegateのメソッド。衝突したときに呼ばれる
    func didBegin(_ contact: SKPhysicsContact) {
        var firstBody: SKPhysicsBody
        var secondBody: SKPhysicsBody
        
        // bird → firstBody
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        } else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        
        // 多重衝突防止処理
        if (firstBody.node?.parent != nil && secondBody.node?.parent != nil) {
            // ゲームオーバーのときは何もしない
            if scrollNode.speed <= 0 {
                return
            }

            if (firstBody.categoryBitMask & scoreCategory) == scoreCategory || (secondBody.categoryBitMask & scoreCategory) == scoreCategory {
                // スコア用の物体と衝突した
                print("ScoreUp")
                score += 1
                scoreLabelNode.text = "Score:\(score)"    // ←追加
            
                // ベストスコア更新か確認する --- ここから ---
                var bestScore = userDefaults.integer(forKey: "BEST")
                if score > bestScore {
                    bestScore = score
                    bestScoreLabelNode.text = "Best Score:\(bestScore)"    // ←追加
                    userDefaults.set(bestScore, forKey: "BEST")
                    userDefaults.synchronize()
                } // --- ここまで追加---
            
            } else if ringo != nil && ringo.parent != nil && ((firstBody.categoryBitMask & ringoCategory) == ringoCategory || (secondBody.categoryBitMask & ringoCategory) == ringoCategory){
                // りんごと衝突した
                print("GetRingo")
                
                // ringoのSKSpriteNodeを削除
                secondBody.node?.removeFromParent()
                
                ringoScore += 1
                ringoScoreLabelNode.text = "Item Score:\(ringoScore)"
                self.run(getRingoSound)
            } else {
                // 壁か地面と衝突した
                print("GameOver")

                // スクロールを停止させる
                scrollNode.speed = 0

                bird.physicsBody?.collisionBitMask = groundCategory

                let roll = SKAction.rotate(byAngle: CGFloat(Double.pi) * CGFloat(bird.position.y) * 0.01, duration:1)
                bird.run(roll, completion:{
                self.bird.speed = 0
                })
            }
        }
    }
    
    func restart() {
        score = 0
        scoreLabelNode.text = "Score:\(score)"    // ←追加
        ringoScore = 0
        ringoScoreLabelNode.text = "Item Score:\(ringoScore)"

        bird.position = CGPoint(x: self.frame.size.width * 0.2, y:self.frame.size.height * 0.7)
        bird.physicsBody?.velocity = CGVector.zero
        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory
        bird.zRotation = 0

        wallNode.removeAllChildren()

        bird.speed = 1
        scrollNode.speed = 1
    }
    
    func setupScoreLabel() {
        score = 0
        scoreLabelNode = SKLabelNode()
        scoreLabelNode.fontColor = UIColor.black
        scoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 60)
        scoreLabelNode.zPosition = 100 // 一番手前に表示する
        scoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        scoreLabelNode.text = "Score:\(score)"
        self.addChild(scoreLabelNode)

        bestScoreLabelNode = SKLabelNode()
        bestScoreLabelNode.fontColor = UIColor.black
        bestScoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 90)
        bestScoreLabelNode.zPosition = 100 // 一番手前に表示する
        bestScoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left

        let bestScore = userDefaults.integer(forKey: "BEST")
        bestScoreLabelNode.text = "Best Score:\(bestScore)"
        self.addChild(bestScoreLabelNode)
        
        ringoScoreLabelNode = SKLabelNode()
        ringoScoreLabelNode.fontColor = UIColor.black
        ringoScoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 120)
        ringoScoreLabelNode.zPosition = 100 // 一番手前に表示する
        ringoScoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left

        ringoScoreLabelNode.text = "Item Score:\(ringoScore)"
        self.addChild(ringoScoreLabelNode)

    }
    
     func setupRingo() {
        // りんごの画像を読み込む
        let ringoTexture = SKTexture(imageNamed: "ringo")
        ringoTexture.filteringMode = .linear
        // 移動する距離を計算（移動時間を壁と合わせる）
        let wallTexture = SKTexture(imageNamed: "wall")
        // 移動する距離を計算
        let movingDistance = self.frame.size.width + wallTexture.size().width
        // 画面外まで移動するアクションを作成
        let moveRingo = SKAction.moveBy(x: -movingDistance, y: 0, duration:4)
        // 自身を取り除くアクションを作成
        let removeRingo = SKAction.removeFromParent()
        // 2つのアニメーションを順に実行するアクションを作成
        let ringoAnimation = SKAction.sequence([moveRingo, removeRingo])
        // 位置の上下の振れ幅を120ptとする
        let random_y_range: CGFloat = 120
        // 空の中央位置(y座標)を取得
        let groundSize = SKTexture(imageNamed: "ground").size()
        let sky_center_y = groundSize.height + (self.frame.size.height - groundSize.height) / 2

        // 空の中央位置を基準にしてアイテムの中央位置を取得
        let ringo_center_y = sky_center_y - ringoTexture.size().height / 2
        // りんごを生成するアクションを作成
        let createRingoAnimation = SKAction.run({
            // りんごのノードを乗せるノードを作成
            self.ringo = SKSpriteNode(texture: ringoTexture)
            // -random_y_range〜random_y_rangeの範囲のランダム値を生成
            let random_y = CGFloat.random(in: -random_y_range...random_y_range)
            // りんごの中央位置にランダム値を足して、表示位置を決定
            let ringo_y = ringo_center_y + random_y
            self.ringo.position = CGPoint(x: self.frame.size.width + ringoTexture.size().width / 2, y: ringo_y)
            self.ringo.zPosition = -50 // 雲より手前、地面より奥

            // スプライトに物理演算を設定する
            self.ringo.physicsBody = SKPhysicsBody(rectangleOf: ringoTexture.size())
            self.ringo.physicsBody?.categoryBitMask = self.ringoCategory
            // 動かないように設定する
            self.ringo.physicsBody?.isDynamic = false
            
            self.ringo.run(ringoAnimation)
            self.ringoNode.addChild(self.ringo)
            
        })
        // 次のりんご作成までの時間待ちのアクションを作成
        let waitAnimation = SKAction.wait(forDuration: 9, withRange: 5)
        // りんごを作成->時間待ち->りんごを作成を無限に繰り返すアクションを作成
        let repeatForeverAnimation = SKAction.repeatForever(SKAction.sequence([waitAnimation, createRingoAnimation]))
        ringoNode.run(repeatForeverAnimation)
    }
    
    // 画面をタップした時に呼ばれる
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if scrollNode.speed > 0 { // 追加
            // 鳥の速度をゼロにする
            bird.physicsBody?.velocity = CGVector.zero

            // 鳥に縦方向の力を与える
            bird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 15))
        } else if bird.speed == 0 { // --- ここから ---
            restart()
        } // --- ここまで追加 ---
    }
}
