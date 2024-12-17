function PI=PI(a,t,niu,pif)
f =@(L) 1.03*exp(-L./5)+pi/2*(1-niu)^2/(1-2*niu)*L.*(1-exp(-L));
L = a/t;
    if L<=pif.L(1)
        PI=1;
    elseif L>=pif.L(end)
        PI = pif.pi_f(end)*f(pif.L(end));
    else
        PI = interp1(pif.L,pif.pi_f,L).*f(L);
    end
end