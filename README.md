# Beartown

Minimalny fundament gry Roblox: Luau, Rojo 7, Git i zasady pracy dla Codexa.

## Wymagania

- Roblox Studio.
- Aktualne stabilne Rojo 7 dostępne jako `rojo` w PATH (`rojo --version`).
- Plugin Rojo do Roblox Studio zgodny z wersją CLI.
- Git do wersjonowania kodu.

Instalacja CLI i pluginu: [dokumentacja Rojo](https://rojo.space/docs/v7/getting-started/installation/).
Projekt używa rozszerzeń `.luau` obsługiwanych przez aktualne Rojo 7.

## Uruchomienie

W katalogu repozytorium uruchom:

```bash
rojo serve
```

1. Otwórz Roblox Studio i nowy **Baseplate** lub istniejący place z Baseplate.
2. W zakładce **Plugins** uruchom plugin **Rojo**.
3. Połącz się przyciskiem **Connect** z `localhost`, port `34872`.
4. Jeśli plugin wyświetli podgląd zmian, zaakceptuj synchronizację projektu.
5. W **Explorer** sprawdź `ServerScriptService/Server/Main`,
   `StarterPlayer/StarterPlayerScripts/Client/Main` i
   `ReplicatedStorage/Shared/Config`.
6. Naciśnij **Play** (F5), aby uruchomić serwer i klienta.
7. Otwórz panel **Output** i włącz wyświetlanie komunikatów obu kontekstów.
   Powinny pojawić się:

```text
[Server] Project connected successfully
[Client] Project connected successfully
```

Zakończ test przyciskiem **Stop**. Serwer Rojo zatrzymasz przez `Ctrl+C` w terminalu.

## Struktura

| Ścieżka | Przeznaczenie / miejsce w Studio |
| --- | --- |
| `src/server/Main.server.luau` | Script serwera w `ServerScriptService/Server` |
| `src/server/MapGenerator.luau` | Serwerowy generator platform w `Workspace/Map` |
| `src/shared/ObbyConfig.luau` | Parametry sekcji, rozmiary, wysokość, odstępy i kolory Obby |
| `src/server/ObbyParts.luau` | Tworzenie platform i punktów odradzania |
| `src/server/ObbySession.luau` | Checkpointy, respawn, kill plane, meta i cleanup |
| `src/server/RoundManager.luau` | Stany rundy, nagrody, jedno odliczanie i regeneracja |
| `src/server/PlayerStats.luau` | Sesyjne IntValue Wins/Coins w leaderstats |
| `src/client/RoundUI.client.luau` | Komunikat zakończenia i odliczanie |
| `src/shared/MathConfig.luau` | Zakres działań, wygląd bramek, odstępy i debounce |
| `src/server/MathProblemGenerator.luau` | Losowanie działań i trzech różnych odpowiedzi |
| `src/server/MathGateGenerator.luau` | Trzy fizyczne sekcje matematyczne i napisy SurfaceGui |
| `src/server/MathGateTriggers.luau` | Serwerowa ocena odpowiedzi i cleanup zdarzeń |
| `src/server/MapConfig.luau` | Moduł zgodności przekazujący nowy ObbyConfig |
| `src/client/Main.client.luau` | LocalScript w `StarterPlayer/StarterPlayerScripts/Client` |
| `src/shared/Config.luau` | Nazwa, wersja, debug, WinReward, CoinReward i NextRoundDelay |
| `default.project.json` | Mapowania Rojo |
| `AGENTS.md` | Zasady architektury, bezpieczeństwa i pracy Codexa |
| `.gitignore` | Wykluczenia plików tymczasowych i wynikowych |

Workspace nie jest mapowany. Planszę edytuj i zapisuj w Studio; synchronizacja
kodu jest przygotowana do pracy z istniejącym Baseplate. Foldery `Server`,
`Client` i `Shared` są zarządzane przez Rojo — ich skrypty edytuj w repozytorium.
Generator tworzy mapę w `Workspace/Map` raz przy uruchomieniu serwera. Obiekty
oznacza atrybutem `ObbyGenerated`. Regeneracja usuwa te obiekty oraz platformy
poprzedniego generatora (`StartPlatform`, `Platform_01`–`Platform_10`), odłącza
stare zdarzenia i resetuje graczy na start. Inne obiekty użytkownika pozostają.
Nie używaj nazw starego generatora dla własnych obiektów w `Map`.

## Test mapy w Studio

1. Uruchom `rojo serve`, połącz plugin z `localhost:34872` i zsynchronizuj skrypty.
2. Otwórz **Script Analysis** i sprawdź brak błędów. Naciśnij **Play** (F5).
   Postać powinna pojawić się na `StartSpawn`, nad zieloną platformą, na wysokości
   około 40 studów. Trasa prowadzi w kierunku −Z.
3. Sprawdź sekcje: 10 niebieskich `Jump`, 5 małych fioletowych `Precision`,
   4 pomarańczowe `ZigZag`, 5 różowych `HeightJump`, trzy zadania matematyczne
   oraz złotą neonową metę. Podstawowa trasa nadal ma 26 platform. Matematyka
   dodaje platformę checkpointu i 6 platform wejścia/wyjścia. Łącznie jest
   76 części, wliczając spawny, ramy, napisy, triggery i KillPlane.
   Wszystkie są wewnątrz `Workspace/Map` i mają `Anchored = true`.
   Podłogi i ściany mają kolizję; triggery odpowiedzi i ich tabliczki nie blokują postaci.
4. Wejdź na turkusowy pad `Checkpoint_01` na `Jump_10`, a następnie spadnij.
   Czerwona strefa pod mapą powinna zabić postać; wrócisz na ten checkpoint.
   Powtórz przy `Precision_05`, `ZigZag_04` i `HeightJump_01` (wejście do
   ostatnich skoków w górę). Dotykaj padów po kolei; wcześniejszy checkpoint
   nie cofa postępu, a pominięcie checkpointu blokuje zaliczenie następnego.
5. Po sekcji wysokościowej zalicz `Checkpoint_05` na `MathCheckpointPlatform`,
   przejdź poprawne bramki trzech zadań i wejdź na `FinishPlatform`.
   Otrzymasz +1 Win i +100 Coins oraz komunikat. Przy włączonym debug w serwerowym
   Output pojawią się `[Round] Player <nazwa> finished round <numer>` i `[Rewards]`.
   Po 8 sekundach wszyscy gracze trafią na początek nowej rundy.
6. W **Test → Server & Clients** uruchom dwóch graczy. Osiągnij różne checkpointy
   i sprawdź niezależne odradzanie. Wyjście gracza usuwa jego stan z serwera.
7. W serwerowym kontekście **Command Bar** podczas testu wykonaj poniższą
   komendę dwa razy. Każde wywołanie rozpoczyna nową rundę przez RoundManager.
   Gracze wrócą na start, checkpointy i meta się zresetują,
   a liczba wygenerowanych części pozostanie równa 76. Sprawdź ponownie śmierć,
   checkpoint i log mety. Obiekt użytkownika o innej nazwie powinien przetrwać.

```lua
require(game:GetService("ServerScriptService").Server.MapGenerator).generate()
local count = 0
for _, part in game:GetService("Workspace").Map:GetDescendants() do
    if part:IsA("BasePart") and part:GetAttribute("ObbyGenerated") then count += 1 end
end
assert(count == 76)
```

Po **Stop** obiekty utworzone w czasie testu znikną; następny **Play** odtworzy mapę.
Zmiany konfiguracji testuj przez **Stop → Play**. Postęp jest wyłącznie w pamięci
serwera; nie ma DataStore. RoundStateEvent służy wyłącznie do wysyłania stanu
z serwera do klienta. Serwer sprawdza dotyk żywej postaci,
bliskość pada i kolejność checkpointów. To nie jest pełny system antycheat
wykrywający teleportowanie postaci.

## Sekcja matematyczna

Za `Checkpoint_05`, przed metą, znajduje się `Workspace/Map/MathSection` z
modelami `MathGate_01`, `MathGate_02`, `MathGate_03`. Każdy ma platformę wejściową,
wyjściową, `QuestionDisplay` wysoko nad trzema `AnswerDoor_1`–`AnswerDoor_3`
oraz osobne `AnswerDisplay_1`–`AnswerDisplay_3`. Wszystkie bramki wyglądają tak samo.
Boczne ściany i wysokie ramy kierują zwykłe przejście przez wybraną odpowiedź.

Każda mapa zawiera po jednym dodawaniu, odejmowaniu i mnożeniu w losowej kolejności.
Składniki dodawania sumują się do maksymalnie 20, odjemnik nie przekracza odjemnej,
a czynniki mnożenia mieszczą się domyślnie w 2–5, z iloczynem do 20. Dwie błędne
odpowiedzi są różne i oddalone od poprawnej o najwyżej 3; wszystkie odpowiedzi
mieszczą się w 0–20. Kolejność odpowiedzi jest tasowana.

`ObbyConfig.Seed = nil` inicjuje losowy strumień przy starcie serwera. Ustaw np.
`Seed = 12345`, aby odtwarzać tę samą sekwencję rund między uruchomieniami serwera.
RoundManager przesuwa strumień Random przy każdej nowej rundzie, więc stały seed
nie zamraża zadań. Pojedyncze działania mogą losowo się powtórzyć. Śmierć i wejście
kolejnego gracza nie losują zadań ponownie.

Serwer wykrywa dotyk żywej postaci i sprawdza jej odległość od bramki. Porównuje
liczby zapisane w swojej pamięci, a nie tekst GUI. Poprawna odpowiedź pozwala
przejść bez teleportacji; błędna ustawia `Humanoid.Health = 0`. Istniejący
`ObbySession` odradza gracza przy ostatnim zaliczonym checkpoincie. Dotychczasowe
checkpointy nadal trzeba zaliczać po kolei, aby aktywować `Checkpoint_05`.

Debounce działa osobno dla gracza, bramki i życia postaci. Nie daje ochrony przed
inną błędną bramką i nie wpływa na pozostałych graczy. Regeneracja odłącza
wszystkie poprzednie triggery; wyjście gracza usuwa jego dane debounce.

## Test matematyki w Studio

1. Uruchom `rojo serve`, połącz plugin Rojo i zsynchronizuj projekt przed **Play**.
2. Przejdź Obby, aktywuj kolejno checkpointy 01–05. Przed matematyką sprawdź,
   że `Players/<gracz>/RespawnLocation` wskazuje `Checkpoint_05` w widoku serwera.
3. Podejdź do pierwszego zadania. Sprawdź czytelność działania nad całą bramą
   i trzech różnych odpowiedzi nad drzwiami, patrząc z platformy wejściowej.
4. Wejdź w złą bramkę: postać powinna umrzeć i odrodzić się przy checkpoincie 05.
   Działanie i kolejność odpowiedzi muszą pozostać takie same. Powtórz na drugim
   i trzecim zadaniu; po błędzie wracasz przed całą sekcję matematyczną.
5. Przejdź poprawne drzwi: zdrowie nie spada i nie ma teleportacji. Sprawdź,
   że zwykłym skokiem nie można ominąć drzwi bokiem ani górą. Kontynuuj do mety.
6. Przy `Config.DebugMode = true` serwer wypisuje wygenerowane zadania oraz wybory.
   Krótkie wielokrotne dotknięcie tej samej bramki nie powinno spamować Output.
   Po ustawieniu `DebugMode = false` i **Stop → Play** komunikaty `[MathGate]`
   nie powinny się pojawiać. Logi rund i nagród również znikają; logi połączenia pozostają.
7. Uruchom **Test → Server & Clients** z dwoma graczami. Zalicz checkpointy
   obydwoma graczami, następnie wybierz jednocześnie dobrą i złą odpowiedź.
   Tylko gracz z błędną odpowiedzią powinien umrzeć. Bramy i zadania pozostają
   bez zmian dla drugiego gracza. Powtórz wybór tej samej bramki obydwoma graczami.
8. Uruchom komendę regeneracji z poprzedniej sekcji dwa razy. Nie powinny powstać
   dodatkowe `MathSection` ani dodatkowe logi z poprzednich triggerów. Gracze
   wracają na start. Przy ustawionym seedzie zadania zmieniają się między rundami;
   cała sekwencja jest powtarzalna po ponownym uruchomieniu serwera.

Sprawdzenia wykonane poza Studio: kompilacja Luau, build Rojo, 9000 wygenerowanych
działań oraz testy logiki dwóch graczy z atrapami API (błędna odpowiedź, respawn,
debounce, stałość zadań, regeneracja). Nie zastępują testu fizyki `Touched`,
czytelności napisów i rzeczywistej sesji multiplayer w Studio.

## Rundy, Wins i Coins

`Main.server.luau` uruchamia `RoundManager.start()` tylko raz. PlayerStats tworzy
`Player/leaderstats/Wins` oraz `Coins` jako IntValue z wartością 0. Statystyki
utrzymują się przez kolejne rundy, ale znikają po wyjściu gracza/wyłączeniu serwera.

`ObbySession` nadal sprawdza żywą postać, bliskość mety i kolejność checkpointów.
Przekazuje zatwierdzone dotknięcie do RoundManager. Manager zapisuje UserId jako
ukończony w aktualnej rundzie przed zmianą statystyk, bez operacji oczekujących
pomiędzy tymi krokami. Ponowne dotykanie mety nie daje kolejnej nagrody.
Wpis ukończenia pozostaje do następnej rundy również po wyjściu gracza.

Przepływ stanów: **Playing → Finishing → Generating → Playing**.
Pierwszy zwycięzca otrzymuje nagrodę i ustala wspólny termin końca za 8 sekund.
Kolejni gracze mogą otrzymać nagrodę przed tym terminem, ale nie zmieniają zegara.
Po jego upływie nagrody są blokowane nawet wtedy, gdy zadanie odliczania wykona
się z opóźnieniem. Generowanie odłącza stare zdarzenia i tworzy nową sesję
checkpointów. Żywe postacie trafiają bezpiecznie nad start z wyzerowaną prędkością;
martwe lub jeszcze nieutworzone postacie dostają nowy spawn przy odrodzeniu.

`ReplicatedStorage/Remotes/RoundStateEvent` powstaje na serwerze. Wysyła pełne
komunikaty `roundFinished`, `countdown`, `newRound` oraz stan generowania/błędu.
Nie ma obsługi `OnServerEvent`. Klient nie może tą drogą zmienić nagrody ani rundy.
JSON w atrybucie gracza `RoundSnapshot` pozwala odtworzyć GUI po późnym załadowaniu
LocalScript. Numer rewizji zapobiega nadpisaniu nowego komunikatu starym.
GUI przeżywa respawn dzięki `ResetOnSpawn = false`.

Numer i stan są dostępne w `RoundManager.CurrentRound`, `RoundManager.State`
oraz jako atrybuty `RoundStateEvent`. Wartości nagród i czasu zmieniaj wyłącznie
w `src/shared/Config.luau`: `WinReward = 1`, `CoinReward = 100`, `NextRoundDelay = 8`.

## Test pętli rund w Studio

1. Uruchom `rojo serve`, połącz plugin, zsynchronizuj skrypty i wybierz **Play**.
   Sprawdź leaderboard: Wins=0, Coins=0. Na serwerze sprawdź atrybuty
   `ReplicatedStorage/Remotes/RoundStateEvent`: CurrentRound=1, State=Playing.
2. Zrób zrzut/zapis działań matematycznych pierwszej rundy. Przejdź trasę z
   checkpointami 01–05 i poprawnymi odpowiedziami; wejdź na metę.
3. Sprawdź Wins=1, Coins=100 oraz własny komunikat nagrody i odliczanie od 8.
   Stój, skacz i wielokrotnie wchodź na metę podczas odliczania: wartości
   powinny pozostać 1/100. Nie powinno wystartować drugie odliczanie.
4. Po 8 sekundach sprawdź CurrentRound=2, State=Playing, schowanie komunikatu,
   powrót na start, RespawnLocation=StartSpawn i zachowane statystyki 1/100.
   Zadania korzystają z dalszej części losowania; mogą sporadycznie się powtórzyć.
   Powtórne ukończenie daje 2/200.
5. Spadnij po zaliczeniu checkpointu, a następnie wybierz błędną bramkę. W obu
   przypadkach sprawdź respawn na ostatnim checkpoincie i brak nagrody.
6. W **Test → Server & Clients** uruchom trzech graczy. A kończy jako pierwszy,
   B około 3 sekundy później, C nie kończy. A i B mają dostać po 1/100, C 0/0.
   B nie przedłuża odliczania; wszyscy trafiają na start nowej rundy.
7. Podczas odliczania zresetuj postać jednego gracza. Sprawdź, że GUI nadal
   pokazuje aktualny czas, a odrodzenie po zmianie rundy używa nowego startu.
   Jeżeli masz możliwość dołączyć kolejnego klienta podczas countdownu,
   sprawdź jego komunikat z pozostałym czasem i początkowe statystyki 0/0.
8. Podczas countdownu w serwerowym **Command Bar** wykonaj:

```lua
require(game:GetService("ServerScriptService").Server.RoundManager).nextRound()
```

   Nowa runda powinna zacząć się od razu. Po upływie starego czasu nie może
   rozpocząć się kolejna. Dawne `MapGenerator.generate()` i `Generate()` kierują
   do tej samej operacji. Nie wywołuj niskopoziomowego `MapGenerator.build()` ręcznie.
9. Ustaw DebugMode=false i uruchom test ponownie. Nagrody i GUI działają nadal,
   ale nie ma logów `[Round]`, `[Rewards]` i `[MathGate]`.

Przeprowadzone testy automatyczne z atrapami API i zegarem obejmują: spam mety,
dwóch zwycięzców w jednej rundzie, brak nagrody za śmierć/błąd, ścisły termin,
gracza bez Character, stare callbacki i timery, dołączenie w trakcie odliczania,
regenerację, błąd generowania i ponowienie, cleanup oraz komunikaty klienta.
Kompilacja Luau i build Rojo przeszły. Faktyczną fizykę, wygląd GUI i multiplayer
w silniku trzeba zweryfikować powyższą procedurą w Studio.

Jeśli generowanie zgłosi błąd, manager przechodzi do **Error**, nie daje nagród
i nie uruchamia kolejnych automatycznych prób. Output podaje przyczynę. Po jej
usunięciu można ponowić `RoundManager.nextRound()` lub zatrzymać i wznowić test.

Domyślny Baseplate i SpawnLocation nie są usuwane. Przy standardowym Baseplate
kill plane znajduje się nad nim (około Y=21). Jeśli własne obiekty zasłaniają
trasę lub przechwytują upadek, ręcznie przenieś albo usuń w Explorer wyłącznie
przeszkadzający Baseplate/SpawnLocation. Serwer ustawia spawn Obby i po załadowaniu
postaci przenosi ją do właściwego punktu, także przy dodatkowych spawnach w Studio.

Pliki binarne `.rbxl` są ignorowane przez Git: zapisuj planszę osobno w Studio.
Tekstowe `.rbxlx` i `.rbxmx` poza katalogami wynikowymi można wersjonować.
Build samego kodu z Rojo nie zawiera planszy edytowanej w Studio.

## Weryfikacja zmian

Sprawdź składnię w Studio przez **Script Analysis** oraz uruchom test **Play**.
Opcjonalny build struktury projektu w PowerShell (nie sprawdza składni Luau):

```powershell
$buildPath = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid().ToString() + '.rbxlx')
try {
    rojo build default.project.json --output $buildPath
    if ($LASTEXITCODE -ne 0) { throw 'Rojo build failed' }
} finally {
    if (Test-Path -LiteralPath $buildPath) { Remove-Item -LiteralPath $buildPath }
}
```
