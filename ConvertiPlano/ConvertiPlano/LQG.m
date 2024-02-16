%% Controllo LQG %%

s = tf('s');

% Linearizzazione sistema convertiplano intorno al punto z = theta = 0 %
A_nom = [-b/m,           0,          0,                   0;
            0,       -beta/J,        0,                   0;
            1,           0,          0,                   0;
            0,           1,          0,                   0];

B_nom = [1/m,                 0;
           0,             2*l/J;
           0,                 0;
           0,                 0];


C_nom = [0,     0,      1,      0;
         0,     0,      0,      1];
    
D_nom = [0, 0;
         0, 0];

% Creazione sistemi attuatori in forma di stato
G1 = tf([Km1], [Tm1 1]) * exp(-s*T1);
G2 = tf([Km2], [Tm2 1]) * exp(-s*T2);
G_att = blkdiag(G1, G2);

G_att = ss(G_att);

A_att = G_att.A;
B_att = G_att.B;
C_att = G_att.C;
D_att = G_att.D;

% Composizione in serie del sistema dinamico e degli attuatori (forma di
% stato)
A_tot = [      A_att,         zeros(2,4);
            B_nom*C_att,         A_nom   ];

B_tot = [B_att;  B_nom*D_att];

C_tot = [D_nom*C_att,   C_nom];

D_tot = [0, 0;
         0, 0];

G = ss(A_tot, B_tot, C_tot, D_tot);

% Definisco le matrici di covarianza dei rumori in ingresso e dei sensori
dev_std_fm = 100;
dev_std_fa = 10;
dev_std_z = 1;
dev_std_theta = 0.3;

% Matrice covarianza rumori in inngresso (gli errori di processo sono
% riferiti solo alle equazioni di z: e theta:)
Q = blkdiag(0, 0, dev_std_fm ^ 2, dev_std_fa ^ 2, 0, 0);

% Matrice covarianza errori di misura (y1 = z; y2 = theta)
R = blkdiag(dev_std_z ^ 2, dev_std_theta ^ 2);

% Big matricione di covarianza
QWV = blkdiag(Q, R);

% Matrice di peso per stati e ingressi, dove pesiamo solo gli ingressi e
% gli stati z e theta
Q_pesi = blkdiag(zeros(4), eye(4));

% lqg(sistema in forma di stato,
%     pesi per stato e ingressi,
%     matrici di covarianza)
[reg, info] = lqg(G, Q_pesi, QWV);

% Guadagno LQR %
Kc = - info.Kx;

% Guadagno filtro di Kalman %
Kf = info.L;

% Matrici di peso per stati (stati + stati da integrare) e ingressi
% Vado a pesare solo z, theta (2 volte sia per stato stimato che stato integrato)e i 2 ingressi
Q_z = blkdiag(zeros(4), blkdiag(1,1,1,0.0001));
R_u = eye(2);

% Calcolo del guadagno del controllore con integratori
Kc_int = -lqi(G, Q_z, R_u);

% K_LQG = [A_tot + B_tot*Kc + Kf*C_tot,    Kf;
%                     Kc,                zeros(2)];

K_LQG = ss(A_tot + B_tot*Kc + Kf*C_tot, Kf, Kc, zeros(2));
K_LQG = zpk(K_LQG);

G = zpk(G);

S = 1/(eye(2) + G*K_LQG);
bodemag(S);

T = G*K_LQG/(eye(2) + G*K_LQG);
bodemag(T);