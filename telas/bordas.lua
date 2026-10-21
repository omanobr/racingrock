-- Teste de bordas (para tirar FOTO no aparelho): como o console desenha imagens que ficam
-- parte para fora da tela. Na v0.1 a pista mostrou pedacos trocados nas bordas da esquerda e
-- da direita quando a tela andava para os lados (tiles meio para fora).
--
--   linhas 1-4: um carro (deitado, 32 px) meio para fora a esquerda e a direita, cada linha
--               mais para fora (a linha 4 esta toda fora: nao deve aparecer nada)
--   linha 5:    o mesmo da linha 2, com ui.clip(0, 0, 480, 270) ligado
--   linhas 6-7: uma fileira de tiles da pista comecando em x = -8 (sem e com ui.clip)
--   linha 8:    um carro andando devagar da esquerda para a direita, passando pelas bordas
--   no alto e embaixo: um carro meio para fora em cima e outro embaixo
-- A: volta ao titulo.
local Cores = require "cores"
local Entrada = require "entrada"

local Tela = {}
Tela.__index = Tela

local DEITADO = 12   -- quadro do carro apontando para a direita

function Tela.nova()
  local car = Sprites.img.car
  return setmetatable({ quadro = 0, espera = 20,
    carros = { car.t_ver, car.t_azu, car.t_ama, car.t_pra }, pista = Sprites.img.p0.p0a }, Tela)
end

function Tela:atualizar()
  self.quadro = self.quadro + 1
  self.espera = self.espera - 1
  if self.espera <= 0 and Entrada.voltar() then Jogo.ir("titulo") end
end

local LINHAS = {   -- y, carro, x da esquerda, x da direita, texto
  { 16, 1, -8, 456, "x = -8 e 456: 24 px de cada carro aparecem" },
  { 50, 2, -16, 464, "x = -16 e 464: 16 px aparecem" },
  { 84, 3, -24, 472, "x = -24 e 472: 8 px aparecem" },
  { 118, 4, -32, 480, "x = -32 e 480: NADA deve aparecer" },
}

function Tela:desenhar()
  local tile = ui.tile
  ui.cls(Cores.cinza_escuro)
  for _, l in ipairs(LINHAS) do
    local img = self.carros[l[2]]
    tile(img, DEITADO, l[3], l[1])
    tile(img, DEITADO, l[4], l[1])
    ui.print(l[5], 120, l[1] + 12, Cores.branco)
  end
  -- linha 5: com recorte ligado
  ui.clip(0, 0, 480, 270)
  tile(self.carros[2], DEITADO, -16, 152)
  tile(self.carros[2], DEITADO, 464, 152)
  ui.clip()
  ui.print("igual a linha 2, com ui.clip ligado", 120, 164, Cores.branco)

  -- linhas 6 e 7: tiles da pista a partir de x = -8 (sem e com recorte)
  for k = 0, 30 do tile(self.pista, (k * 5) % 150, -8 + k * 16, 188) end
  ui.clip(0, 0, 480, 270)
  for k = 0, 30 do tile(self.pista, (k * 5) % 150, -8 + k * 16, 206) end
  ui.clip()

  -- linha 8: carro andando (passa pelas duas bordas)
  local x = self.quadro % 560 - 40
  tile(self.carros[1], DEITADO, x, 228)
  ui.print(string.format("x = %d", x), 216, 260, Cores.amarelo)

  -- em cima e embaixo, meio para fora
  tile(self.carros[3], 0, 440, -16)
  tile(self.carros[3], 24, 440, 254)

  ui.print("TESTE DE BORDAS: tire uma FOTO e mande. A: sair", 100, 2, Cores.amarelo)
end

return Tela
