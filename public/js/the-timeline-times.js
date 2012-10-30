$(function(){
    var $container = $('#container');
    var opts = {
        isAnimated: true,
        isFitWidth: true,
        duration: 400,
        columnWidth : 280,
        itemSelector : '.item'
    };

    $container.imagesLoaded(function(){
        $container.masonry(opts);
    });
});
