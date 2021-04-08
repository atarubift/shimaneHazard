require 'dxopal'
include DXOpal

GAME_INFO = {
  scene: :title,
  score: 0,
  life: 5,
}

Window.width  = 800
Window.height = 600
Window.bgcolor = [135, 206, 235]

Image.register(:bg, 'images/bg.png')
Image.register(:ed1, 'images/ed1.png')
Image.register(:ed2, 'images/ed2.png')
Image.register(:enemy, 'images/enemy.png')
Image.register(:enemy2, 'images/enemy2.png')
Image.register(:kumo, 'images/kumo.png')
Image.register(:op, 'images/op.png')
Image.register(:player, 'images/player.png')
Image.register(:syringe, 'images/syringe.png')
Image.register(:virous, 'images/virous.png')
Image.register(:way, 'images/way.png')

class Way < Sprite
  def initialize(x, y)
    way_image = Image[:way]
    way_image.set_color_key(C_WHITE)
    super(x, y, way_image)
  end

  def update
    self.x -= 5
    if self.x + 100 <= 0
      self.vanish
    end
  end

  def ene_obs
  end
end

class Ways
  attr_reader :ways, :obstacle
  MAX_WAYS = 8

  def initialize
    @ways = []
    @obstacle = []
    @way_x = 0
    @count = 0
    @cnt_obs = 0
    @cnt_o_obs = 0
    @cnt_t_obs = 0
  end

  def update(enemies)
    Sprite.check(@obstacle, enemies, shot=:ene_obs, hit=:obs_ene)
    Sprite.update(@ways)
    Sprite.clean(@ways)
    Sprite.update(@obstacle)
    Sprite.clean(@obstacle)
    (MAX_WAYS - @ways.size).times do
      @ways << Way.new(800 + 100 * -@way_x, 500, 100, 100)

        if rand(1..100) > 80
          @obstacle << Way.new(800, 400, 100, 100)
        end

      if @count == 0
        if @way_x <= MAX_WAYS
          @way_x += 1
        else
          @count = 1
          @way_x = 0
        end
      else
        @way_x = 0
      end
    end
  end

  def draw
    Sprite.draw(@ways)
    Sprite.draw(@obstacle)
  end

  def getter
    @obstacle
  end
end

class Player < Sprite
  def initialize
    @pl_img = Image[:player]
    @pl_img.set_color_key(C_WHITE)
    x = 100
    y = 490
    @dy = 0
    @pl_sp = 5
    super(x, y, @pl_img)
    @flag = 0
    @jump_flag = false
    @under = self.y + @pl_img.height
  end

  def update
    jump
    slide
    gravity
    if self.y > 600 || self.x < 60
      @flag = 1
    end
  end

  def getFlag
    @flag
  end

  def gravity
    @under += @dy
    self.y = @under - @pl_img.height
    @dy += 1
  end

  def jump
    if Input.key_push?(K_UP) && @jump_flag
      @dy = - 16
      @jump_flag = false
    end
  end

  def slide
    @speed_mag = 2
    if Input.key_down?(K_LEFT) && self.x > 100
      self.x -= @pl_sp * @speed_mag
    elsif Input.key_down?(K_RIGHT) && self.x + @pl_img.width < 800
      self.x += @pl_sp
    end
  end

  def shot_way(d)
    @under = d.y
    @dy = 0
    @jump_flag = true
  end

  def shot_obs(d)
    if @under - @dy < d.y
      @under = d.y
      @dy = 0
      @jump_flag = true
    elsif d.x + 3 > self.x && @under > d.y
      self.x = d.x - @pl_img.width
    elsif d.x + 100 < self.x + 3
      self.x += @pl_sp
    end
  end
end

class Enemy < Sprite
  def initialize(x, y)
    @ene_sp = 5
    ene_img = Image[:enemy]
    ene_img.set_color_key(C_WHITE)
    super(x, y, ene_img)
  end

  def update
    self.x -= @ene_sp
    if self.x + 45 <= 0
      self.vanish
    end
  end

  def hit
    self.vanish
    GAME_INFO[:score] += 1
  end

  def shot
    self.vanish
    GAME_INFO[:life] -= 1
  end

  def obs_ene
    self.vanish
  end
end

class Enemies
  attr_reader :enemies
  MAX_ENEMY = 5

  def initialize
    @enemies = []
    @enemyPlace = [330, 430]
  end

  def update(plyer)
    Sprite.update(@enemies)
    Sprite.clean(@enemies)
    Sprite.check(@enemies, plyer)

    (MAX_ENEMY - @enemies.size).times do
      if (rand(1..100)) > 99
        @enemies << Enemy.new(800, @enemyPlace[rand(0..1)])
      end
    end
  end

  def draw
    Sprite.draw(@enemies)
  end

  def getter
    @enemies
  end
end

class Bullet < Sprite
  def initialize(x, y)
    bu_img = Image[:syringe]
    bu_img.set_color_key(C_BLACK)
    super(x, y, bu_img)
    @bu_sp = 5
  end

  def update
    self.x += @bu_sp
    if self.x > 800
      self.vanish
    end
  end

  def shot
    self.vanish
  end
end

class Bullets
  MAX_BULLET = 5
  attr_reader :box

  def initialize
    @box = []
    @count = 0
  end

  def udpate(enemies, ways, x, y)
    Sprite.check(@box, enemies)
    Sprite.check(@box, ways)
    Sprite.update(@box)
    Sprite.clean(@box)

    if Input.key_push?(K_SPACE) && @box.size < MAX_BULLET
      @box << Bullet.new(x + 100, y + 20)
    end
  end

  def draw
    Sprite.draw(@box)
  end
end

class Game 
  def initialize
    reset
  end

  def reset
    GAME_INFO[:scene] = :title
    GAME_INFO[:score] = 0
    GAME_INFO[:life] = 5
    @font = Font.new(32)
    @ways = Ways.new
    @plyer = Player.new
    @enemies = Enemies.new
    @bullets = Bullets.new
  end

  def run
    Window.loop do
      case GAME_INFO[:scene]
      when :title
        Window.draw(100, 100, Image[:op])
        Window.draw_font(500, 300, "STARAT:SPACE", @font)
        Window.draw_font(500, 100, "SHIMANE HAZARD", @font)
        if Input.key_push?(K_SPACE)
          GAME_INFO[:scene] = :playing
        end
      when :playing
        Window.draw(0, 150, Image[:bg])
        Window.draw_font(600, 20, "SCORE: #{ GAME_INFO[:score] }", @font)
        Window.draw_font(100, 20, "LIFE: #{ "●" * GAME_INFO[:life] }", @font)
        Sprite.check(@plyer, @ways.ways, shot=:shot_way)
        Sprite.check(@plyer, @ways.obstacle, shot=:shot_obs)
        # Sprite.check(@enemies, @ways.obstacle, shot=:obs_ene)
        # Sprite.check(@bullets, @ways.obstacle, shot=:bullt_way)
        @enemies.update(@plyer)
        @enemies.draw
        @ways.update(@enemies.getter)
        @ways.draw
        @plyer.update
        @plyer.jump
        @plyer.draw
        @bullets.udpate(@enemies.getter, @ways.getter, @plyer.x, @plyer.y)
        @bullets.draw
        if GAME_INFO[:score] == 10
          GAME_INFO[:scene] = :clear
        elsif GAME_INFO[:life] == 0 || @plyer.getFlag == 1
          GAME_INFO[:scene] = :game_over
        end
      when :game_over
        Window.draw_font(500, 300, "go", @font)
        if Input.key_push?(K_SPACE)
          GAME_INFO[:scene] = :clear
        end
      when :clear
        Window.draw_font(500, 300, "cl", @font)
        if Input.key_push?(K_SPACE)
          GAME_INFO[:scene] = :title
          reset
        end
      end
    end
  end
end

Window.load_resources do
  game = Game.new
  game.run
end
