-- *******
-- Copyright (C) JSFOUR - All Rights Reserved
-- You are not allowed to sell this script or re-upload it
-- Visit my page at https://github.com/jonassvensson4
-- Written by Jonas Svensson, July 2018
-- *******

local ESX = nil
TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

-- Get money
ESX.RegisterServerCallback('jsfour-atm:getMoney', function(source, cb)
  local _source = source
	local xPlayer = ESX.GetPlayerFromId(_source)
  local data = {
    bank = xPlayer.bank,
    cash = xPlayer.money
  }
  cb(data)
end)

-- Get user info
ESX.RegisterServerCallback('jsfour-atm:getUser', function(source, cb)
  local _source = source
	local identifier = ESX.GetPlayerFromId(_source).identifier
  local userData = {}

  MySQL.Async.fetchAll('SELECT playerName FROM users WHERE identifier = @identifier', {['@identifier'] = identifier},
  function (result)
    if (result[1] ~= nil) then
      MySQL.Async.fetchAll('SELECT account FROM jsfour_atm WHERE identifier = @identifier', {['@identifier'] = identifier},
      function (resulto)
        if (resulto[1] ~= nil) then
          table.insert(userData, {
            firstname = result[1].playerName,
            lastname = result[1].lastname,
            account = resulto[1].account
          })
          cb(userData)
        end
      end)
    end
  end)
end)

-- Check item
ESX.RegisterServerCallback('jsfour-atm:item', function(source, cb)
  local xPlayer = ESX.GetPlayerFromId(source)
  local item    = xPlayer.getInventoryItem('creditcard').count
  if item > 0 then
    cb(true)
  else
    cb(false)
  end
end)

-- Insert money
RegisterServerEvent('jsfour-atm:insert')
AddEventHandler('jsfour-atm:insert', function(amount)
	local _source = source
	local xPlayer = ESX.GetPlayerFromId(_source)
	amount = tonumber(amount)
	if amount > xPlayer.money then
		print("JSFOUR-ATM: ERROR")
	else
		xPlayer.removeMoney(amount)
		xPlayer.addBank(amount)
		TriggerClientEvent('esx:showNotification', _source, 'You deposited $' .. amount .. '~s~')
	end
end)

-- Take money
RegisterServerEvent('jsfour-atm:take')
AddEventHandler('jsfour-atm:take', function(amount)
	local _source = source
	local xPlayer = ESX.GetPlayerFromId(_source)
	amount = tonumber(amount)
	local accountMoney = 0
	accountMoney = xPlayer.bank
	if amount > accountMoney then
		print("JSFOUR-ATM: ERROR")
	else
		xPlayer.removeBank(amount)
		xPlayer.addMoney(amount)
		TriggerClientEvent('esx:showNotification', _source, 'You withdrew $' .. amount .. '~s~ ')
	end
end)

-- Transfer money
RegisterServerEvent('jsfour-atm:transfer')
AddEventHandler('jsfour-atm:transfer', function(amount, receiver)
  local _source = source

  MySQL.Async.fetchAll('SELECT identifier FROM jsfour_atm WHERE account = @account', {['@account'] = receiver},
  function (result)
    if (result[1] ~= nil) then
      local recPlayer    = ESX.GetPlayerFromIdentifier(result[1].identifier)
      local senPlayer    = ESX.GetPlayerFromId(_source)
    	local amount       = tonumber(amount)
    	local accountMoney = senPlayer.bank

    	if amount >= accountMoney then
    		print("JSFOUR-ATM: ERROR")
    	else
    		senPlayer.removeBank(amount)
        recPlayer.addBank(amount)
        MySQL.Async.fetchAll('SELECT playerName FROM users WHERE identifier = @identifier', {['@identifier'] = result[1].identifier},
        function (result)
          if (result[1] ~= nil) then
            TriggerClientEvent('esx:showNotification', _source, 'You Sent $' .. amount .. '~s~ to ' .. string.gsub(result[1].playerName, "_", " ") )
            TriggerClientEvent('esx:showNotification', recPlayer.source, 'You got $' .. amount .. '~s~ sent to you from ' .. string.gsub(result[1].playerName, "_", " ") )
          end
        end)
      end
    end
  end)
end)

-- Create bank-account
RegisterServerEvent('jsfour-atm:createAccount')
AddEventHandler('jsfour-atm:createAccount', function( src )
  math.randomseed(math.floor(os.time() + math.random(1000)))

  local _source = source
  local identifier = nil

  if src == nil then
    identifier = ESX.GetPlayerFromId(_source).identifier
  else
    identifier = ESX.GetPlayerFromId(src).identifier
  end

  local account = math.random(1000000000,9999999999)

  MySQL.Async.fetchAll('SELECT account FROM jsfour_atm WHERE account = @account', {['@account'] = account},
  function (result)
    if (result[1] == nil) then
      MySQL.Async.fetchAll('SELECT identifier FROM jsfour_atm WHERE identifier = @identifier', {['@identifier'] = identifier},
      function (result)
        if (result[1] == nil) then
          MySQL.Async.execute('INSERT INTO jsfour_atm (identifier, account) VALUES (@identifier, @account)',
            {
              ['@identifier']   = identifier,
              ['@account']      = account
            }
          )
        end
      end)
    else
      TriggerEvent('jsfour-atm:createAccount', _source)
    end
  end)
end)

-- Create card *NOT IN USE*
RegisterServerEvent('jsfour-atm:createCard')
AddEventHandler('jsfour-atm:createCard', function( src )
  math.randomseed(math.floor(os.time() + math.random(1000)))

  local _source = source
  local identifier

  if src == nil then
    identifier = ESX.GetPlayerFromId(_source).identifier
  else
    identifier = ESX.GetPlayerFromId(src).identifier
  end

  local number = math.random(0000000000000000,9999999999999999)
  local code = math.random(0000,9999)

  MySQL.Async.fetchAll('SELECT number FROM creditcard WHERE number = @number', {['@number'] = number},
  function (result)
    if (result[1] == nil) then
      MySQL.Async.execute('INSERT INTO creditcard (owner, number, code) VALUES (@owner, @number, @code)',
        {
          ['@owner']      = identifier,
          ['@number']     = number,
          ['@code']       = code
        }
      )
    else
      TriggerEvent('jsfour-atm:createCard', _source)
    end
  end)
end)