# Введение

NTLM и Kerberos аутентификация может и не самый распространенный тип аутентификации в .Net Core, тем не менее есть проекты, где использование данного типа аутентификации необходимо. И, если в случае с деплоем на Windows системах проблем как правило не возникает, то в случае с Linux в интернете трудно найти how-to-guide, чтобы использовать аутентификацию на основе kerberos. Ниже я покажу на простом примере, как настроить аутентификацию в linux и asp net core на основе kerberos тикетов.

# Тестовый проект

В качестве проекта для проверки работы авторизации возьмем стандартный пустой проект на .Net 5 и внесем в него несколько модификаций.

Для работы авторизации нужно добавить в ConfigureServices AddNegotiate:
```
services.AddAuthentication()
    .AddNegotiate();
```

Создадим контроллер, который вызовет аутентификацию:
```
public class HomeController : Controller
    {
        [Authorize(AuthenticationSchemes = NegotiateDefaults.AuthenticationScheme)]
        public IActionResult Index()
        {
            return Ok($"Success! User: {User.Identity.Name}");
        }
    }
```

Когда мы запустим проект в Windows и попадем на сервер, то мы авторизуемся под локальным пользователем, с которого мы авторизованы в Windows.

# Dockerfile

Взглянем на содержимое Dockerfile. Самым важным моментом является установка пакета krb5-user
```
RUN apt-get update && apt-get install -y \
    krb5-user
```
и задание дефолтного пути для чтения keytab файла.
```
ENV KRB5_KTNAME=/mnt/volume/krb5.keytab
```
Данный файл необходим для Negotiate handler-а, чтобы успешно провалидировать передаваемый от пользователя kerberos тикет.

Для сборки образа на Linux машине используем
```
docker build -t netcore-kerberos -f Dockerfile .
```

# Настройка передачи тикета в Windows

Для того, чтобы получить keytab файл для валидации тикетов, нужно выполнить следующее.

1) Для Linux машины, где мы запустим наш контейнер, зарегистрировать доменное имя в DNS сервере вида:
```
netcore-kerberos.mydomain.com
```

2) Ввести компьютер с именем netcore-kerberos в домен. Это можно сделать стандартными средствами на контроллере домена.

3) На контроллере домена выполнить следующие команды:
```
setspn -S HTTP/netcore-kerberos.mydomain.com netcore-kerberos
setspn -S HTTP/netcore-kerberos@MYDOMAIN.COM netcore-kerberos
ktpass -princ HTTP/netcore-kerberos.mydomain.com@MYDOMAIN.COM -mapuser MYDOMAIN\netcore-kerberos$ -crypto ALL -ptype KRB5_NT_PRINCIPAL -pass +rndpass -out krb5.keytab
```
При вводе команд регистр важен!

4) Скопировать файл krb5.keytab на Linux машину. Например, в ~/netcore-kerveros-volume

5) Для того, чтобы windows при запросе kerberos тикета автоматически пересылал его, нужно настроить следующие параметры:    
На машине пользователя, с которого планируем заходить на наш сервер,
открываем Internet Explorer, открываем Internet Options, Вкладка Security, выбираем Internet, нажимаем кнопку Custom Level, находим пункт User Authentication, Logon, выбираем "Automatic Logon with current user name and password"    
По умолчанию выбрана настройка "Automatic logon only in Intranet zone", поэтому
можно просто добавить DNS адрес сервера в Intranet Zone, чтобы тикет пересылался автоматически.    
Все эти настройки можно настроить и через доменные политики Active Directory.


Имя netcore-kerberos приведено для примера, может быть любое.

# Запуск

Запускаем контейнер:
```
docker run -p 5100:80 -v ~/netcore-kerveros-volume:/mnt/volume --hostname netcore-kerberos netcore-kerberos
```
Порт можно выбрать любой.

Заходим с другой windows машины, введенной в домен, на адрес netcore-kerberos.mydomain.com    
Нас должно успешно авторизовать и показать доменное имя пользователя.

Enjoy!

---
https://blogs.manageengine.com/active-directory/2018/08/02/securing-zone-levels-internet-explorer.html    
 https://techtime.co.nz/display/TECHTIME/How+do+I+add+a+trusted+site+to+my+Local+Intranet+Zone+using+a+Group+Policy    
https://docs.microsoft.com/ru-ru/aspnet/core/security/authentication/windowsauth?view=aspnetcore-5.0&tabs=visual-studio    
https://docs.microsoft.com/ru-ru/aspnet/core/security/authentication/windowsauth?view=aspnetcore-5.0&tabs=visual-studio#linux-and-macos-environment-configuration
