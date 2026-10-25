-- Corrida rapida: escolhe a pista, o carro, o nivel dos rivais e se todos levam minas, e corre
-- (sem campeonato). A direita, o mapinha da pista e o carro em 3/4 com a ficha.
local C = require "config"
local Entrada = require "entrada"
local Cores = require "cores"
local Carros = require "carros"
local Pista = require "pista"
local Menu = require "menu"
local Texto = require "texto"
local D = require "dados_interface"
local Selecao = require "dados_selecao"

local Tela = {}
Tela.__index = Tela

local TRACAO = { traseira = "TRASEIRA", dianteira = "DIANTEIRA", integral = "INTEGRAL" }

-- a ficha do carro numa linha (tambem usada na garagem)
function Tela.ficha(m)
  return string.format("VELOC %d  ACEL %d  ADER %d  BLIND %d  ARMA %d  TRACAO %s", m.velocidade, m.aceleracao,
    m.aderencia, m.blindagem, m.arma, TRACAO[m.tracao] or "?")
end

-- a ficha em duas colunas de barrinhas (garagem, loja, corrida rapida), canto em (x, y)
local NOTAS = { { "VELOCIDADE", "velocidade" }, { "ACELERACAO", "aceleracao" }, { "ADERENCIA", "aderencia" },
                { "BLINDAGEM", "blindagem" }, { "ARMA", "arma" } }
function Tela.ficha_barras(m, x, y)
  for i, n in ipairs(NOTAS) do
    local ly = y + (i - 1) * 10
    ui.print(n[1], x, ly, Cores.cinza_claro)
    for k = 1, 5 do
      ui.rectfill(x + 66 + (k - 1) * 9, ly, x + 72 + (k - 1) * 9, ly + 6, k <= m[n[2]] and Cores.amarelo or Cores.cinza_escuro)
    end
  end
  ui.print("TRACAO " .. (TRACAO[m.tracao] or "?"), x, y + 52, Cores.cinza_claro)
end

-- o carro em 3/4 (img/car/<id>_3q) centralizado em cx, com o chao em y_chao
function Tela.carro(m, cx, y_chao)
  local t = Selecao[m.id]
  ui.spr(Sprites.img.car[m.id .. "_3q"], cx - t[1] // 2, y_chao - t[2])
end

-- mapinha de uma pista (img/mapa/<id>, folha de 1 tile) centralizado em cx, com o topo em y;
-- espelho: da pista espelhada
function Tela.mapa(id, cx, y, espelho)
  local d = D.mapas[id]
  if d then ui.tile(Sprites.img.mapa[id], espelho and 1024 or 0, cx - d.w // 2, y) end
end

local minas = false     -- todos levam um pacote de minas?

local menu = Menu.novo({
  { texto = "CORRER", acao = function()
    local n = minas and C.MINAS or 0
    Jogo.ir("corrida", { pista = C.PISTA, variante = C.VARIANTE, voltas = Pista.LISTA[C.PISTA].voltas,
                         nivel = C.NIVEL, minas = n, minas_rivais = n })
  end },
  { texto = "PISTA", acao = function() C.PISTA = C.PISTA % Pista.quantas() + 1 end },
  { texto = "VARIA\xC7\xC3O", acao = function() C.VARIANTE = C.VARIANTE % #Pista.VARIANTES + 1 end },
  { texto = "CARRO", acao = function() C.MODELO = Carros[Carros.indice(C.MODELO) % #Carros + 1].id end },
  { texto = "N\xCDVEL", acao = function() C.NIVEL = C.NIVEL % #C.NIVEIS + 1 end },
  { texto = "MINAS", acao = function() minas = not minas end },
  { texto = "VOLTAR", acao = function() Jogo.ir("titulo") end },
}, 52, 48, 22, 150)

function Tela.nova()
  return setmetatable({}, Tela)
end

function Tela:atualizar()
  if Entrada.voltar() then Jogo.ir("titulo") return end
  menu:atualizar()
end

function Tela:desenhar()
  Menu.fundo()
  Menu.cabecalho("CORRIDA R\xC1PIDA")
  menu:desenhar()
  -- pista
  local p = Pista.LISTA[C.PISTA]
  Menu.painel(196, 36, 272, 92)
  ui.print("PISTA", 204, 42, Cores.cinza)
  ui.print(p.nome, 204, 54, Cores.branco)
  local v = Pista.VARIANTES[C.VARIANTE]
  ui.print(v.nome ~= "" and v.nome or "NORMAL", 204, 66, Cores.amarelo)
  ui.print(p.voltas .. " VOLTAS", 204, 78, Cores.cinza_claro)
  Tela.mapa(p.id, 400, 44, v.espelho)
  -- carro
  local m = Carros[Carros.indice(C.MODELO)]
  Menu.painel(196, 134, 272, 110)
  ui.print("CARRO", 204, 140, Cores.cinza)
  Texto.escrever("f2", m.nome, 204, 152, "amarelo")
  Tela.ficha_barras(m, 204, 174)
  Tela.carro(m, 400, 228)
  -- nivel e minas
  Menu.painel(16, 206, 172, 38)
  ui.print("RIVAIS: " .. C.NIVEIS[C.NIVEL].id:upper(), 24, 212, Cores.branco)
  ui.print(minas and "MINAS: 3 PARA CADA UM" or "MINAS: NAO (SO METRALHADORA)", 24, 226,
    minas and Cores.verde or Cores.cinza_claro)
  Menu.rodape(Entrada.NOME.confirmar .. ": ESCOLHER/TROCAR   " .. Entrada.NOME.voltar .. ": VOLTAR")
end

return Tela
