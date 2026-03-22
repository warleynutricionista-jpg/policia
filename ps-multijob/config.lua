Config = Config or {}

-- Lado da tela onde você quer que a interface apareça. Pode ser "left" ou "right"
Config.Side = "right"

Config.MaxJobs = 3
Config.IgnoredJobs = {
	["unemployed"] = true,
}

Config.DenyDuty = {
	["ambulance"] = true,
	["police"] = true,
}

Config.WhitelistJobs = {
	["police"] = true,
	["ambulance"] = true,
	["mechanic"] = true,
	["judge"] = true,
	["lawyer"] = true,
}

Config.Descriptions = {
	["police"] = "Enfrente criminosos ou seja um bom policial e prenda-os",
	["ambulance"] = "Cuide dos feridos e salve vidas",
	["mechanic"] = "Conserte veículos e mantenha a cidade rodando",
	["tow"] = "Pegue o guincho e recolha veículos pela cidade",
	["taxi"] = "Busque passageiros pela cidade e leve-os ao destino",
	["bus"] = "Transporte várias pessoas pela cidade até seus destinos",
	["realestate"] = "Venda casas e ajude clientes a encontrar um lar",
	["cardealer"] = "Venda carros e feche bons negócios",
	["judge"] = "Decida se as pessoas são culpadas ou inocentes",
	["lawyer"] = "Defenda os inocentes ou represente os culpados",
	["reporter"] = "Cubra notícias e mantenha a cidade informada",
	["trucker"] = "Dirija um caminhão e faça entregas",
	["garbage"] = "Dirija um caminhão de lixo e mantenha a cidade limpa",
	["vineyard"] = "Trabalhe no vinhedo e cuide das plantações",
	["hotdog"] = "Venda cachorros-quentes pela cidade",
}

-- Altere os ícones para qualquer ícone gratuito do Font Awesome e adicione aqui outros empregos do seu servidor
-- Lista: https://fontawesome.com/search?o=r&s=solid
Config.FontAwesomeIcons = {
	["police"] = "fa-solid fa-handcuffs",
	["ambulance"] = "fa-solid fa-user-doctor",
	["mechanic"] = "fa-solid fa-wrench",
	["tow"] = "fa-solid fa-truck-tow",
	["taxi"] = "fa-solid fa-taxi",
	["bus"] = "fa-solid fa-bus",
	["realestate"] = "fa-solid fa-sign-hanging",
	["cardealer"] = "fa-solid fa-cards",
	["judge"] = "fa-solid fa-gave",
	["lawyer"] = "fa-solid fa-gavel",
	["reporter"] = "fa-solid fa-microphone",
	["trucker"] = "fa-solid fa-truck-front",
	["garbage"] = "fa-solid fa-trash-can",
	["vineyard"] = "fa-solid fa-wine-bottle",
	["hotdog"] = "fa-solid fa-hotdog",
}
