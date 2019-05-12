COMPONENT=SenderAppC
include $(MAKERULES)
PFLAGS += -I$(TOSDIR)/lib/printf
BUILD_EXTRA_DEPS=BuildToRadioMsg.class
BlinkToRadioMsg.class: BlinkToRadioMsg.java
	javac BlinkToRadioMsg.java
BlinkToRadioMsg.java:
	mig java -target=null -java-classname=BlinkToRadioMsg Sender.h BlinkToRadioMsg -o $@


