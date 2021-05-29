function ES(h, e, i, pS, pI, pC)
    pS > 0 ? h - e * (1 + (pC / (pS + pI))) : 0
end

function EI(h, e, i, pS, pI, pC)
pI > 0 ? h - e - i : 0
end

function EC(h, e, i, pS, pI, pC)
    pC > 0 ? h * (pS / (pS + pI)) : 0
end

function E(h, e, i, pS, pI, pC)
    params = (h, e, i, pS, pI, pC)
    [ES(params...), EI(params...), EC(params...)]
end

# Replicator Dynamics:

avg_util(h, e, i, pS, pI, pC) = (pS * ES(h, e, i, pS, pI, pC) + pI * EI(h, e, i, pS, pI, pC) + pC * EC(h, e, i, pS, pI, pC))

dpS(h, e, i, pS, pI, pC) = pS * (ES(h, e, i, pS, pI, pC) - avg_util(h, e, i, pS, pI, pC))
dpI(h, e, i, pS, pI, pC) = pI * (EI(h, e, i, pS, pI, pC) - avg_util(h, e, i, pS, pI, pC))
dpC(h, e, i, pS, pI, pC) = pC * (EC(h, e, i, pS, pI, pC) - avg_util(h, e, i, pS, pI, pC))