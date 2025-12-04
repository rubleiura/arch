# ##############################################
# ## 🖋️ НАСТРОЙКА NANO (chroot) #################
# ##############################################
#
# Зачем: Глубокая настройка редактора nano.
# Включает: Цвета, подсветку, автоотступы, табы, softwrap, поддержку мыши.

clear

# Объединяем все изменения sed в одну команду для эффективности
sudo sed -i '
s/# set autoindent/set autoindent/g;
s/# set constantshow/set constantshow/g;
s/# set indicator/set indicator/g;
s/# set linenumbers/set linenumbers/g;
s/# set multibuffer/set multibuffer/g;
s/# set quickblank/set quickblank/g;
s/# set smarthome/set smarthome/g;
s/# set softwrap/set softwrap/g;
s/# set tabsize 8/set tabsize 4/g;
s/# set tabstospaces/set tabstospaces/g;
s/# set trimblanks/set trimblanks/g;
s/# set unix/set unix/g;
s/# set wordbounds/set wordbounds/g;
s/# set titlecolor bold,white,magenta/set titlecolor bold,white,magenta/g;
s/# set promptcolor black,yellow/set promptcolor black,yellow/g;
s/# set statuscolor bold,white,magenta/set statuscolor bold,white,magenta/g;
s/# set errorcolor bold,white,red/set errorcolor bold,white,red/g;
s/# set spotlightcolor black,orange/set spotlightcolor black,orange/g;
s/# set selectedcolor lightwhite,cyan/set selectedcolor lightwhite,cyan/g;
s/# set stripecolor ,yellow/set stripecolor ,yellow/g;
s/# set scrollercolor magenta/set scrollercolor magenta/g;
s/# set numbercolor magenta/set numbercolor magenta/g;
s/# set keycolor lightmagenta/set keycolor lightmagenta/g;
s/# set functioncolor magenta/set functioncolor magenta/g;
s/# include \/usr\/share\/nano\/\*\.nanorc/include \/usr\/share\/nano\/\*\.nanorc/g;
#s/# set mouse/set mouse/g; # Включаем поддержку мыши
# Добавим строку для отключения строки справки, если это нужно пользователю
# s/# set nohelp/set nohelp/g;
' /etc/nanorc

clear
echo ""
echo "######################################"
echo "## <<< НАСТРОЙКА NANO ЗАВЕРШЕНА >>> ##"
echo "######################################"
