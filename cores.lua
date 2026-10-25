-- Cores do codigo. So cores da paleta base (ferramentas/paleta.py): a paleta do servidor do
-- Lupi so acumula, entao cor nova no codigo ocupa uma vaga para sempre.
local hex = Palette.hex

local Cores = {
  preto = hex(0x080808),
  cinza_escuro = hex(0x393939),
  cinza = hex(0x8C8C8C),
  cinza_claro = hex(0xCECECE),
  branco = hex(0xFFFFFF),
  vermelho = hex(0xDE3929),
  azul = hex(0x3973EF),
  amarelo = hex(0xEFC629),
  laranja = hex(0xEF7B10),
  verde = hex(0x52DE52),
  fundo = hex(0x181818),           -- fundo dos menus
  vinho = hex(0x6B1010),           -- faixa da opcao escolhida
  amarelo_escuro = hex(0xBD9410),
  azul_claro = hex(0x8CB5FF),
  terra = hex(0xAD8C63),           -- poeira (rastros.lua)
  terra_escura = hex(0x8C6B4A),
}

return Cores
