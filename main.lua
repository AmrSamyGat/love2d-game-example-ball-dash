app = love -- just a warper to make it easier to read
W, H = app.graphics.getDimensions()
PLAYER_WIDTH = 100
PLAYER_HEIGHT = 20
PLAYER_SPEED = 5
MIN_X, MAX_X = 0, W-PLAYER_WIDTH
MAX_SPEED = 7 -- max speed for the ball
gameover = false
local first_create = true
local hits = 0
text = "" -- UI text
function Player(self) -- to draw a player
    app.graphics.setColor(self.color[1], self.color[2], self.color[3])
    app.graphics.rectangle("fill", self.x, self.y, PLAYER_WIDTH, PLAYER_HEIGHT)
    return self 
end
function isTouchedByABall(self, ballp) -- checks whether the ball touched the specified player or not
    if getTouchedPart(self, ballp) then 
        return true 
    else
        return false
    end
end
function createBall(self) -- to create and draw the ball
    if self.isDead == true then return end
    app.graphics.setColor(self.color[1], self.color[2], self.color[3])
    app.graphics.circle("fill", self.x, self.y, self.r)
    self.isDead = false
    first_create = false
    if self.movingStart then -- start moving to the bottom as its created (the ball)
        self.y = self.y + self.speed
    end
    return self 
end
function destroyBall(self) -- kills the ball
    app.graphics.setColor(self.color[1], self.color[2], self.color[3])
    self.isDead = true
    self.movingStart = true
    self.speed = 3
    self.x = (W/2)-15
    self.y = (W/2)-15
    --[[
        reseting ball info
    ]]
    return self 
end

function getTouchedPart(self, ball)
    local Px, Py = self.x, self.y
    local Bx, By = ball.x, ball.y
    local deltaX = Bx-Px
    if deltaX < 0 or deltaX > PLAYER_WIDTH then
        return false
    end
    if self.id == 1 then 
        if By+ball.r < Py or By+ball.r > Py+PLAYER_HEIGHT then
            return 
        end
    elseif self.id == 2 then 
        if By-ball.r < Py or By-ball.r > Py+PLAYER_HEIGHT then
            return 
        end
    end
    return deltaX/PLAYER_WIDTH
    --[[
        -- JUST TO UNDERSTAND --
        CASES....
        ball x = 20
        player x = 10
        player width = 100
        ball position for player is 20-10
        ---------------------------------
        ball x = 10
        player x = 20
        out of range (comes before the player)
        ---------------------------------
        ball x = 110
        player x = 10
        out of range (since the default width for the player is 100px, it'd be out of range)
        ---------------------------------
    ]]
end
function moveBall(self) -- moving the ball with slope handling
    if self.isDead then return end
    if self.moveType == nil then return end
    local x1 = lasthitx
    local x2 = ball.x
    if self.moveType == 1 then --up
        local x3 = player1.x + 50
        self.y = self.y - self.speed
        self.x = self.x + self.slope
    elseif self.moveType == 2 then --down
        local x3 = player2.x + 50
        self.y = self.y + self.speed
        self.x = self.x + self.slope
    end
end
function gameOver() -- ends the game and outputs the name of the winner
    ball:destroy()
    local winner = "NONE"
    winner = player1.score > player2.score and "PLAYER 1" or "PLAYER 2"
    if player1.score == player2.score then 
        winner = "NONE"
    end
    text = "GAME OVER! The winner is: "..winner.."!\nPress 'Space' to start a new game."
    gameover = true
end
function makeSlope(p, b) -- changes the slope value for the ball as it touches a player
    local maxSlope = 1.5
    local part = getTouchedPart(p, b)
    if(part) then
        if part > 0.5 then
            b.slope = (part-0.5)*maxSlope
        else
            b.slope = -1*((part+0.5)*maxSlope)
        end
    end
end

-- Players and ball objects
player1 = {id=1, x=(W/2)-PLAYER_WIDTH, y=H-PLAYER_HEIGHT, color={255, 0, 0}, Player=Player, isTouched=isTouchedByABall, score=0}
player2 = {id=2, x=(W/2)-PLAYER_WIDTH, y=0, color={0, 0, 255}, Player=Player, isTouched=isTouchedByABall, score=0}
ball = {x=(W/2)-15, y=(W/2)-15, r=15, slope=0, color={255, 255, 255}, moveType=nil, isDead=false, move=moveBall, create=createBall, destroy=destroyBall, speed=3, movingStart=true}
lasthitx = ball.x

function app.load() -- set title on loading (same as love.load() function for the framework)
    app.window.setTitle("Ball dash!")
end
function app.update() -- update per frame (same as love.update())
    -- player one controls
    if app.keyboard.isDown("right") then
        if player1.x >= W-100 then return end
        player1.x = player1.x+PLAYER_SPEED
    end
    if app.keyboard.isDown("left") then 
        if player1.x <= 0 then return end
        player1.x = player1.x-PLAYER_SPEED
    end
    -- player two controls
    if app.keyboard.isDown("d") then -- right
        if player2.x >= W-100 then return end
        player2.x = player2.x+PLAYER_SPEED
    end
    if app.keyboard.isDown("a") then -- left
        if player2.x <= 0 then return end
        player2.x = player2.x-PLAYER_SPEED
    end
    if player1:isTouched(ball) then
        player1.score = player1.score+math.random(10, 20)
        ball.movingStart =  false
        lasthitx = ball.x
        ball.moveType = 1
        hits = hits+1
        if ball.speed <= MAX_SPEED then
            if hits >=2 then 
                hits = 0
                ball.speed = ball.speed+1
            end
        end
        makeSlope(player1, ball)
    elseif player2:isTouched(ball) then
        player2.score = player2.score+math.random(10, 20)
        ball.movingStart =  false
        ball.moveType = 2
        lasthitx = ball.x
        if ball.speed < MAX_SPEED then
            if hits >=2 then 
                hits = 0
                ball.speed = ball.speed+1
            end
        end
        makeSlope(player2, ball)
    end
    -- end the game when a player misses the ball
    if not player1:isTouched(ball) and ball.y > H+10 then
        gameOver()
    elseif not player2:isTouched(ball) and ball.y < -10 then
        gameOver()
    end
    -- reset game if the game was over and the player pressed 'space' key
    if gameover and app.keyboard.isDown("space") then
        player1 = {id=1, x=(W/2)-PLAYER_WIDTH, y=H-PLAYER_HEIGHT, color={255, 0, 0}, Player=Player, isTouched=isTouchedByABall, score=0}
        player2 = {id=2, x=(W/2)-PLAYER_WIDTH, y=0, color={0, 0, 255}, Player=Player, isTouched=isTouchedByABall, score=0}
        ball = {x=(W/2)-15, y=(W/2)-15, r=15, slope=0, color={255, 255, 255}, moveType=nil, isDead=false, move=moveBall, create=createBall, destroy=destroyBall, speed=3, movingStart=true}
        lasthitx = ball.x
        gameover = false
    end
end
function app.draw() -- draw some UI text and create the players and the ball (same as love.draw())
    if gameover then app.graphics.print("\n\n\n"..text) text2 = "" return end
    player1:Player()
    app.graphics.print("Player 1 score: "..player1.score)
    player2:Player()
    app.graphics.print("\nPlayer 2 score: "..player2.score)
    ball:create()
    ball:move()
end