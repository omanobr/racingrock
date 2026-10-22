-- Letras grandes em tiles: "f2" (img/ui/f2, 12x16, cores branco/amarelo/cinza) e "f3"
-- (img/ui/f3, 17x23, amarelo), feitas por ferramentas/gerar_interface.py. Uma letra = um tile:
-- tiles seguidos da mesma folha custam 4 bytes cada na lista de desenho do console.
-- Aceita acentos e o ordinal (1o): o console guarda os .lua em Latin-9 (1 byte por letra) e o
-- simulador em UTF-8 (2 bytes); os dois jeitos funcionam, sem utf8.* (que quebra no console).
-- O texto pequeno continua com ui.print (so ASCII).
local D = require "dados_interface"

local Texto = {}

local byte, tile = string.byte, ui.tile

-- letra que comeca na posicao i de s: codigo (Latin-1/Latin-9, iguais nas letras do portugues)
-- e a posicao da proxima
local function codigo(s, i)
  local b = byte(s, i)
  if b == 0xC2 or b == 0xC3 then          -- UTF-8 de 2 bytes (simulador)
    local b2 = byte(s, i + 1)
    if b2 and b2 >= 0x80 and b2 <= 0xBF then return (b - 0xC2) * 64 + b2, i + 2 end
  end
  return b, i + 1                          -- ASCII ou Latin-9 (console)
end

-- letra acentuada = letra + acento (por cima; a cedilha, por baixo)
local COMPOSTA = {
  [0xC1] = { 65, "agudo" }, [0xC0] = { 65, "grave" }, [0xC2] = { 65, "circ" }, [0xC3] = { 65, "til" },
  [0xC9] = { 69, "agudo" }, [0xCA] = { 69, "circ" }, [0xCD] = { 73, "agudo" }, [0xD3] = { 79, "agudo" },
  [0xD4] = { 79, "circ" }, [0xD5] = { 79, "til" }, [0xDA] = { 85, "agudo" }, [0xC7] = { 67, "cedilha" },
}

local FONTES = {}
for _, nome in ipairs({ "f2", "f3" }) do
  FONTES[nome] = { img = Sprites.img.ui[nome], d = D[nome], cache = {} }
end
Texto.F2, Texto.F3 = D.f2, D.f3

-- o texto convertido em { tile, dx, dy, tile, dx, dy, ... } (guardado: os menus e o painel
-- desenham os mesmos textos todo quadro)
local function montar(d, s, base)
  local letras, e = d.letras, d.escala
  local lista, n, i, cx = {}, 0, 1, 0
  while i <= #s do
    local cp
    cp, i = codigo(s, i)
    if (cp >= 0x61 and cp <= 0x7A) or (cp >= 0xE0 and cp <= 0xFE and cp ~= 0xF7) then cp = cp - 32 end
    local t = letras[cp]
    if t then
      lista[n + 1], lista[n + 2], lista[n + 3] = base + t, cx, 0
      n = n + 3
    else
      local c = COMPOSTA[cp]
      if c then
        lista[n + 1], lista[n + 2], lista[n + 3] = base + letras[c[1]], cx, 0
        lista[n + 4], lista[n + 5] = base + letras[c[2]], cx
        lista[n + 6] = c[2] == "cedilha" and 7 * e + 1 or -(2 * e + 1)
        n = n + 6
      end
    end
    cx = cx + d.avanco
  end
  lista.largura = cx
  return lista
end

local function lista_de(nome, s, cor)
  local f = FONTES[nome]
  cor = cor or "amarelo"
  local por_cor = f.cache[cor]
  if not por_cor then
    por_cor = {}
    f.cache[cor] = por_cor
  end
  local lista = por_cor[s]
  if not lista then
    lista = montar(f.d, s, f.d.cores[cor])
    por_cor[s] = lista
  end
  return lista, f.img
end

-- escreve s com o canto de cima a esquerda em (x, y); devolve a largura
function Texto.escrever(nome, s, x, y, cor)
  local lista, img = lista_de(nome, s, cor)
  for i = 1, #lista, 3 do tile(img, lista[i], x + lista[i + 1], y + lista[i + 2]) end
  return lista.largura
end

function Texto.largura(nome, s)
  return (lista_de(nome, s, nil)).largura
end

function Texto.centro(nome, s, y, cor)
  return Texto.escrever(nome, s, 240 - Texto.largura(nome, s) // 2, y, cor)
end

-- numero inteiro >= 0 alinhado a direita (a ultima letra termina em x_dir), sem montar texto:
-- para valores que mudam todo quadro (velocidade)
function Texto.numero(nome, n, x_dir, y, cor)
  local f = FONTES[nome]
  local d = f.d
  local base, letras, av, img = d.cores[cor or "amarelo"], d.letras, d.avanco, f.img
  local x = x_dir - av
  repeat
    tile(img, base + letras[48 + n % 10], x, y)
    n = n // 10
    x = x - av
  until n == 0
end

-- um tile solto da folha f2 (palheta, faixa zebrada)
function Texto.extra(nome, x, y)
  tile(FONTES.f2.img, D.f2[nome], x, y)
end

return Texto
