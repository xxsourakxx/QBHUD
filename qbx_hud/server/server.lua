-- Reserved for server-side extensions such as stress syncing integrations.
-- Intentionally lightweight for minimal performance impact.

RegisterNetEvent('qbx_hud:server:syncStress', function(value)
    local src = source
    TriggerClientEvent('qbx_hud:client:setStress', src, tonumber(value) or 0)
end)
